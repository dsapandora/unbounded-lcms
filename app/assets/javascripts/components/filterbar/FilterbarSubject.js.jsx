function FilterbarSubject(props) {
  const className = classNames(
    'o-filterbar__item',
    'o-filterbar__item--rectangle',
    `o-filterbar__item--${props.colorCode}`,
    {'o-filterbar__item--deselected': !props.selected}
  );

  return (
    <div className={className} onClick={props.onClick}>{props.displayName}</div>
  );
}
