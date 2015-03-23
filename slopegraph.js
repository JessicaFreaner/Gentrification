d3.custom = {};
d3.custom.slopegraph = function() {
    console.log('in slopegraph');
    var opts = {
        width: 600,
        height: 900,
        margin: {top: 20, right: 100, bottom: 50, left: 150},
        labelLength: 50
    };

    function exports(selection) {
        console.log('in exports');
        selection.each(function (dataset) {
            console.log(selection);
            var chartHeight = opts.height - opts.margin.top - opts.margin.bottom;
            var chartWidth = opts.width - opts.margin.right - opts.margin.left;


            // // Get the data
            // d3.tsv("test.tsv", function(error, data) {
            //   data.forEach(function(d) {
            //     d.borough = d.borough;
            //     d.neighborhood = d.neighborhood;
            //     d.station = +d.station;
            //     d.latitude = +d.latitude;
            //     d.longitude = +d.longitude;
            //     d.brunch_start = +d.brunch_start;
            //     d.brunch_end = +d.brunch_end;
            //   });


            var parent = d3.select(this);
            console.log(this);
            var svg = parent.selectAll("svg.chart-root").data([0]);
            svg.enter().append("svg").attr("class", "chart-root")
                    .append('g').attr('class', 'chart-group');
            svg.attr({width: opts.width, height: opts.height});
            // svg.exit().remove();
            var chartSvg = svg.select('.chart-group');

            var data = d3.transpose(dataset.data);
            // var scale = d3.scale.linear().domain(d3.extent(d3.merge(data))).range([chartHeight, 0]);
            var yscale = d3.scale.linear().domain([10,50]).range([chartHeight + opts.margin.top, opts.margin.top]);
            
            var yAxis = d3.svg.axis()
                .scale(yscale)
                .tickSize(chartWidth + opts.margin.left - opts.labelLength)
                // .tickFormat("%")
                .orient("right");

            var gy = chartSvg.append("g")
                .attr("class", "y axis")
                .attr("transform", "translate( 0 , 0 )")
                .call(yAxis);

            gy.selectAll("g").filter(function(d) { return d; })
                .classed("minor", true);

            gy.selectAll("text")
                .attr("x", 4)
                .attr("dy", -4);


            dataNest = d3.nest()
                    .key(function(d) {return d.borough;})
                    .entries(data);


            var lines = chartSvg.selectAll('line.slope-line')
                .data(data);
            lines.enter().append("line")
            lines.attr({
                    class: 'slope-line',
                    x1: opts.margin.left + opts.labelLength,
                    x2: opts.width - opts.margin.right - opts.labelLength,
                    y1: function(d) { return yscale(d[0]); },
                    y2: function(d) { return yscale(d[1]); }})
                .on("mouseover", function(){
                    d3.select(this)
                      .transition()
                      .duration(50)
                      .style("stroke-width", 5)
                });

            var leftLabels = chartSvg.selectAll('text.left_labels')
                .data(data);
            leftLabels.enter().append('text');
            leftLabels.attr({
                    class: 'left_labels slope-label',
                    x: opts.margin.left + opts.labelLength - 10,
                    y: function(d,i) { return yscale(d[0]); },
                    dy: '.35em',
                    'text-anchor': 'end'})
                .text(function(d,i) { return '+ ' + dataset.label[0][i] + '  ' + d[0]})
                .on("mouseover", function(){
                    d3.select(this)
                      .transition()
                      .duration(50)
                      .style("font-size", 25)
                      .style("fill", "red")

                });
            // leftLabels.exit().remove();


          // .on("mouseover", function(){
          //     if (d.active != true) {
          //       d3.selectAll("#tag"+d.key.replace(/\s+/g, ''))
          //         .transition()
          //         .duration(50)
          //         .style("opacity", 1)
          //       d3.select(this)
          //         .transition()
          //         .duration(50)
          //         .style("font-size", function() {
          //           if (d.active != true) {return 25} 
          //         })
          //         ;


            var rightLabels = chartSvg.selectAll('text.right_labels')
                .data(data);
            rightLabels.enter().append('text');
            rightLabels.attr({
                    class: 'right_labels slope-label',
                    x: opts.width - opts.margin.right - opts.labelLength + 10,
                    y: function(d,i) { return yscale(d[1]); },
                    dy: '.35em'})
                .text(function(d,i) { return d[1] });
            // rightLabels.exit().remove();
        });
    }

    exports.opts = opts;
    createAccessors(exports);

    return exports;
}


createAccessors = function(visExport) {
    for (var n in visExport.opts) {
        if (!visExport.opts.hasOwnProperty(n)) continue;
        visExport[n] = (function(n) {
            return function(v) {
                return arguments.length ? (visExport.opts[n] = v, this) : visExport.opts[n];
            }
        })(n);
    }
};