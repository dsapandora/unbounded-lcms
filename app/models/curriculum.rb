#
# `Curriculum` models the hierarchies between educational documents:
#
#   - A document might be a map, a grade, a module, an unit or a lesson.
#   - A map has many grades, a grade has many modules, and so on.
#   - A particular module or unit might appear in MULTIPLE grades or modules.
#
# A `Curriculum` row can have a parent column, which is another `Curriculum`.
# This is how it represents a parent-child relationship.
#
# A `Curriculum` row can also reference a `Resource`, or another `Curriculum`.
# When it references another `Curriculum`, it is referencing another hierarchy.
# Example:
#
# Grade Curriculum          Module Cur. 1            Unit Cur. 1
# |                         |                        |
# | Module Cur. 1 (Cur ref) | Unit Cur. 1 (Cur ref)  | Lesson 1 (Resource ref)
# | Module Cur. 2 (Cur ref) | Unit Cur. 2 (Cur ref)  | Lesson 2 (Resource ref)
#
# In other words, a `Curriculum` tree can reference `Resources` directly, but
# it may also reference another tree.
#
# The root of a `Curriculum` tree will always reference a `Resource`.
# The children of the root will probably reference other trees.
#
# `Curriculum#resource` will find the `Curriculum` `Resource` even if it is
# an indirect reference through a tree.
#
# To make tree navigation more convenient in curriculums that reference
# other curriculums, a resolved copy of the parent curriculum can be created
# with `Curriculum#create_tree`.
#
# The copy will have all its references resolved as resources, and is available
# at `Curriculum#tree`.
#
# We're using the library `closure_tree`, which gives us handy methods to deal
# with trees.
# See: https://github.com/mceachen/closure_tree#accessing-data
#
class Curriculum < ActiveRecord::Base
  acts_as_tree order: 'position', dependent: :destroy

  belongs_to :parent, class_name: 'Curriculum', foreign_key: 'parent_id'
  belongs_to :seed, class_name: 'Curriculum', foreign_key: 'seed_id'

  belongs_to :curriculum_type

  belongs_to :item, polymorphic: true, autosave: true
  belongs_to :resource_item, class_name: 'Resource',
    foreign_key: 'item_id', foreign_type: 'Resource'
  belongs_to :curriculum_item, class_name: 'Curriculum',
    foreign_key: 'item_id', foreign_type: 'Curriculum'

  has_many :referrers, class_name: 'Curriculum', as: 'item'

  has_many :resource_slugs, dependent: :destroy
  alias_attribute :slugs, :resource_slugs

  # Scopes

  scope :with_resources, -> {
    joins(:resource_item).where(item_type: 'Resource')
  }

  scope :with_curriculums, -> {
    joins(:curriculum_item).where(item_type: 'Curriculum')
  }

  scope :seeds, -> { where(seed_id: nil) }
  scope :trees, -> { where.not(seed_id: nil) }

  scope :where_subject, ->(subjects) {
    subjects = Array.wrap(subjects)
    return where(nil) unless subjects.any?

    with_resources
    .joins(resource_item: [:subjects])
    .where(subjects: { id: Array.wrap(subjects).map(&:id) })
  }

  scope :where_grade, ->(grades) {
    grades = Array.wrap(grades)
    return where(nil) unless grades.any?

    with_resources
    .joins(resource_item: [:grades])
    .where(grades: { id: Array.wrap(grades).map(&:id) })
  }

  scope :seeds, -> { where(seed_id: nil) }
  scope :trees, -> { where.not(seed_id: nil) }

  scope :ela, -> { where_subject(Subject.ela) }
  scope :math, -> { where_subject(Subject.math) }

  scope :maps, -> { where(curriculum_type: CurriculumType.map) }
  scope :grades, -> { where(curriculum_type: CurriculumType.grade) }
  scope :modules, -> { where(curriculum_type: CurriculumType.module) }
  scope :units, -> { where(curriculum_type: CurriculumType.unit) }
  scope :lessons, -> { where(curriculum_type: CurriculumType.lesson) }

  def self.ela_tree
    ela.maps.trees.first
  end

  def self.math_tree
    math.maps.trees.first
  end

  def item_is_resource?; item_type == 'Resource'; end
  def item_is_curriculum?; item_type == 'Curriculum'; end

  def resource
    if item_is_resource?
      item
    elsif item_is_curriculum?
      item.item
    end
  end

  def update_position(new_position)
    transaction do
      ordered = parent.children.to_a
      ordered.insert(new_position, ordered.delete_at(position))
      ordered.each_with_index { |c,i| c.update_attributes(position: i) }
    end
  end

  # Navigation

  def map?; current_level == :map; end
  def grade?; current_level == :grade; end
  def module?; current_level == :module; end
  def unit?; current_level == :unit; end
  def lesson?; current_level == :lesson; end

  def current_level
    curriculum_type.name.to_sym
  end

  def hierarchy
    [:lesson, :unit, :module, :grade, :map]
  end

  def next_node
    siblings_after.first
  end

  def previous_node
    siblings_before.last
  end

  def children_of_type(_type = current_level)
    self_and_descendants.where(curriculum_type: CurriculumType.send(_type))
  end

  def current_of_type(_type = current_level)
    self_gen = hierarchy.find_index(current_level)
    needle_gen = hierarchy.find_index(_type)

    return nil if self_gen > needle_gen

    parent = self

    (needle_gen - self_gen).times do
      parent = parent.parent
    end

    parent   
  end

  def first_of_type(_type = current_level)
    self_gen = hierarchy.find_index(current_level)
    needle_gen = hierarchy.find_index(_type)

    if self_gen < needle_gen
      nil
    elsif self_gen == needle_gen
      self
    elsif self_gen == (needle_gen+1)
      children.first
    elsif self_gen > (needle_gen+1)
      children.find { |c| c.first_of_type(_type) }.try(:first_of_type, _type)
    end
  end

  def last_of_type(_type = current_level)
    self_gen = hierarchy.find_index(current_level)
    needle_gen = hierarchy.find_index(_type)

    if self_gen < needle_gen
      nil
    elsif self_gen == needle_gen
      self
    elsif self_gen == (needle_gen+1)
      children.reverse.first
    elsif self_gen > (needle_gen+1)
      children.reverse.find { |c| c.last_of_type(_type) }.try(:last_of_type, _type)
    end
  end

  def next_of_type(_type = current_level)
    self_gen = hierarchy.find_index(current_level)
    needle_gen = hierarchy.find_index(_type)

    if self_gen < needle_gen
      parent.next_of_type(_type)
    elsif self_gen == needle_gen
      next_node || parent.try(:next_of_type, _type)
    elsif self_gen > needle_gen
      if parent.nil?
        nil
      else
        siblings_after
          .find { |s| s.first_of_type(_type) }
          .try(:first_of_type, _type) ||
            parent.try(:next_of_type, _type)
      end
    end
  end

  def previous_of_type(_type = current_level)
    self_gen = hierarchy.find_index(current_level)
    needle_gen = hierarchy.find_index(_type)

    if self_gen < needle_gen
      parent.previous_of_type(_type)
    elsif self_gen == needle_gen
      previous_node || parent.try(:previous_of_type, _type)
    elsif self_gen > needle_gen
      if parent.nil?
        nil
      else
        siblings_before
          .reverse
          .find { |s| s.last_of_type(_type) }
          .try(:last_of_type, _type) ||
            parent.try(:previous_of_type, _type)
      end
    end
  end

  def current_lesson; current_of_type(:lesson); end
  def current_module; current_of_type(:module); end
  def current_unit;   current_of_type(:unit);   end
  def current_grade;  current_of_type(:grade);  end

  def next_lesson; next_of_type(:lesson); end
  def next_module; next_of_type(:module); end
  def next_unit;   next_of_type(:unit);   end
  def next_grade;  next_of_type(:grade);  end

  def previous_lesson; previous_of_type(:lesson); end
  def previous_module; previous_of_type(:module); end
  def previous_unit;   previous_of_type(:unit);   end
  def previous_grade;  previous_of_type(:grade);  end

  def lessons; children_of_type(:lesson); end
  def units; children_of_type(:unit); end
  def modules; children_of_type(:module); end
  def grades; children_of_type(:grade); end

  # Shadow tree

  def tree
    if seed.present?
      root
    else
      self.class.where(seed_id: self.id, parent_id: nil).first
    end
  end

  def create_tree_recursively(seed_root = self, seed_leaf = self, tree = nil)
    tree = self.class.create!(
      item: seed_leaf.resource,
      curriculum_type: seed_leaf.curriculum_type,
      parent: tree,
      position: seed_leaf.position,
      seed: seed_root
    )

    # If the seed_leaf node is a *reference* to another tree, recurse through
    # the referenced tree.
    # Otherwise - if the seed_leaf node is itself a tree - recurse through
    # the seed_leaf node.
    if seed_leaf.item_is_curriculum?
      recurse_from = seed_leaf.item 
    else 
      recurse_from = seed_leaf
    end

    recurse_from.children.each do |s|
      create_tree_recursively(seed_root, s, tree)
    end

    tree
  end

  def create_tree(force: false)
    raise ArgumentError.new('Only root nodes may have trees!') if parent.present?
    raise ArgumentError.new('Only seed nodes may have trees!') if seed.present?

    if tree.nil? || force
      transaction do
        tree.try(:destroy)
        create_tree_recursively
      end
    end

    tree.try(:reload)
  end

  def tree_or_create
    tree || create_tree
  end

  # Slugs

  def create_slugs
    transaction do
      tree.self_and_descendants.find_each do |curriculum|
        ResourceSlug.create_for_curriculum(curriculum)
      end
    end
  end

  def slug
    slugs.where(canonical: true).first
  end

  # Drawing (for debugging)
  def self._draw_node_recursively(node, depth, stop_at)
    padding = '  '*depth
    sep = depth == 0 ? '' : '-> '
    desc = "#{node.position}. ##{node.id} #{node.resource.title} -> #{node.item_type}, id #{node.item_id}, slug #{node.slug.value}"
    puts "#{padding}#{sep}#{desc}"

    return if stop_at == depth

    node.children.each_with_index do |child, i|
      _draw_node_recursively(child, depth+1, stop_at)
    end
  end

  # Draw a text representation of the tree
  def _draw(stop_at = nil)
    old_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = nil
    self.class._draw_node_recursively(self, 0, stop_at)
    ActiveRecord::Base.logger = old_logger
    nil
  end

end
