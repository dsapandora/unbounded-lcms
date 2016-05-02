function AssociationPickerResults(props) {
  let items;

  const shouldAllowCreate = _.isString(props.value) && props.value.length > 0
    && props.allowCreate && props.items.length == 0;

  if (shouldAllowCreate) {
    let newItem = { id: props.value, name: props.value, _create: true };
    items = [(
      <tr key={newItem.id}>
        <td onClick={() => props.onSelectItem(newItem)}>
          {props.value}
          <span className="o-assocpicker-create">(Create)</span>
        </td>
      </tr>
    )];
  } else {
    items = props.items.map(item => {
      let newItem = { id: item.id, name: item.name, _create: false };
      return (
        <tr key={newItem.id}>
          <td onClick={() => props.onSelectItem(newItem)}>{newItem.name}</td>
        </tr>
      );
    });
  }

  return (
    <table className="c-admcur-items">
      <thead>
        <tr>
          <th>Name</th>
        </tr>
      </thead>
      <tbody>
        {items}
      </tbody>
    </table>
  );
}
