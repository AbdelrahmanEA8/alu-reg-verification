/*-----------------------------------------------------------------------------
 File        : agent.sv
 Description : ALU agent. Builds the sequencer, driver and monitor, and
               connects the driver to the sequencer (pull model).
-----------------------------------------------------------------------------*/

class agent extends component_base;
    sequencer sqr;
    driver dvr;
    monitor mon;

    function new(string name, component_base parent);
        super.new(name, parent);
        sqr = new("sqr", this);
        dvr = new("dvr", this);
        mon = new("mon", this);
        dvr.sref = sqr;
    endfunction

endclass