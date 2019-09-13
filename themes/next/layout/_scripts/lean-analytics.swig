
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
25
26
27
28
29
30
31
32
33
34
35
36
37
38
39
40
41
42
43
44
45
46
47
48
49
50
51
52
53
54
55
56
57
58
59
60
61
62
63
64
65
66
67
68
69
70
71
72
73
74
75
76
77
78
79
80
81
82
<!-- custom analytics part create by xiamo -->
<script src="https://cdn1.lncld.net/static/js/av-core-mini-0.6.1.js"></script>
<script>AV.initialize("{{theme.leancloud_visitors.app_id}}", "{{theme.leancloud_visitors.app_key}}");</script>
<script>
function showTime(Counter) {
  var query = new AV.Query(Counter);
  $(".leancloud_visitors").each(function() {
    var url = $(this).attr("id").trim();
    query.equalTo("url", url);
    query.find({
      success: function(results) {
        if (results.length == 0) {
          var content = '0 ' + $(document.getElementById(url)).text();
          $(document.getElementById(url)).text(content);
          return;
        }
        for (var i = 0; i < results.length; i++) {
          var object = results[i];
          var content = object.get('time') + ' ' + $(document.getElementById(url)).text();
          $(document.getElementById(url)).text(content);
        }
      },
      error: function(object, error) {
        console.log("Error: " + error.code + " " + error.message);
      }
    });

  });
}

function addCount(Counter) {
  var Counter = AV.Object.extend("Counter");
  url = $(".leancloud_visitors").attr('id').trim();
  title = $(".leancloud_visitors").attr('data-flag-title').trim();
  var query = new AV.Query(Counter);
  query.equalTo("url", url);
  query.find({
    success: function(results) {
      if (results.length > 0) {
        var counter = results[0];
        counter.fetchWhenSave(true);
        counter.increment("time");
        counter.save(null, {
          success: function(counter) {
            var content =  counter.get('time') + ' ' + $(document.getElementById(url)).text();
            $(document.getElementById(url)).text(content);
          },
          error: function(counter, error) {
            console.log('Failed to save Visitor num, with error message: ' + error.message);
          }
        });
      } else {
        var newcounter = new Counter();
        newcounter.set("title", title);
        newcounter.set("url", url);
        newcounter.set("time", 1);
        newcounter.save(null, {
          success: function(newcounter) {
              console.log("newcounter.get('time')="+newcounter.get('time'));
            var content = newcounter.get('time') + ' ' + $(document.getElementById(url)).text();
            $(document.getElementById(url)).text(content);
          },
          error: function(newcounter, error) {
            console.log('Failed to create');
          }
        });
      }
    },
    error: function(error) {
      console.log('Error:' + error.code + " " + error.message);
    }
  });
}
$(function() {
  var Counter = AV.Object.extend("Counter");
  if ($('.leancloud_visitors').length == 1) {
    addCount(Counter);
  } else if ($('.post-title-link').length > 1) {
    showTime(Counter);
  }
}); 
</script>