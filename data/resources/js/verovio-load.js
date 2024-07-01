document.addEventListener("DOMContentLoaded", (event) => {
   verovio.module.onRuntimeInitialized = async _ => {
       function renderMusic (sourceID, sourceDocUri) {
            let tk = new verovio.toolkit();
            console.log("Verovio has loaded!");
            tk.setOptions({
                scale: 30 //,
                // landscape: true
            });
            console.log("Verovio options:", tk.getOptions());
            // render the mei data
            //let svg = tk.renderData("sourceDocUri", {});
    	    //document.getElementById(sourceID).innerHTML = svg ;
       }
    }
});
