/*-----------------------------------------------------------------------------
 File        : component_base.sv
 Description : Abstract base class for all verification components. Stores
               the instance name and parent handle, and builds the
               hierarchical path name used in reports.
-----------------------------------------------------------------------------*/

virtual class component_base;

  // instance name and parent pointer declarations
  protected string name;
  component_base parent;

  // constructor with name and parent arguments
  function new (string name, component_base parent);
    this.name = name;
    this.parent = parent;
  endfunction

  // read instance name
  virtual function string getname();
    return name;
  endfunction

 // construct hierarchical instance name path
 function string pathname();
    component_base ptr = this;
    pathname = name;
    while (ptr.parent != null) begin
      ptr = ptr.parent;
      pathname = {ptr.name, ".", pathname};
    end
  endfunction : pathname

 // print pathname
  virtual function void print();
   $display("@ %s",this.pathname());
  endfunction

endclass


