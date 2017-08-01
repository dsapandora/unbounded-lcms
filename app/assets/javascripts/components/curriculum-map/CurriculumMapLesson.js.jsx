function CurriculumMapLesson(props) {
  const curriculum = props.curriculum;
  const isActive = _.includes(props.active, curriculum.id) || props.isActiveBranch;
  const cssClasses = classNames(
    'o-c-map__lesson',
    {[`${props.mapType}-bg--base`]: !isActive,
     [`${props.mapType}-bg--${props.colorCode} ${props.mapType}-bg--active`]: isActive,
     [`o-c-map__assessment--${isActive ? props.colorCode : 'base'} ${props.mapType}-bg--assessment`]: props.isAssessment }
  );
  return (
    <ResourceHover cssClasses={cssClasses}
                   resource={curriculum.resource}
                   handlePopupState={props.handlePopupState}/>
  );
}
