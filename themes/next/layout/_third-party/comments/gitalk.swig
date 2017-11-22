{% if not (theme.duoshuo and theme.duoshuo.shortname) and not theme.duoshuo_shortname %}
{% if theme.gitalk.enable and theme.gitalk.client_id %}
<!-- LOCAL: You can save these files to your site and update links -->
  {% set CommentsClass = "Gitalk" %}
  <link rel="stylesheet" href="https://unpkg.com/gitalk/dist/gitalk.css">
  <script src="https://unpkg.com/gitalk/dist/gitalk.min.js"></script>
<!-- END LOCAL -->
    {% if page.comments %}
      <script type="text/javascript">
      function renderGitalk(){
        var gitalk = new {{CommentsClass}}({
            owner: '{{ theme.gitalk.owner }}',
            repo: '{{ theme.gitalk.repo }}',
            clientID: '{{ theme.gitalk.client_id }}',
            clientSecret: '{{ theme.gitalk.client_secret }}',
            admin: '{{ theme.gitalk.admin }}',
            {% if theme.gitalk.distraction_free_mode %}
              distractionFreeMode: '{{ theme.gitalk.distraction_free_mode }}'
            {% endif %}
            });
        gitalk.render('gitalk-container');
      }
      renderGitalk();
      </script>
    {% endif %}
{% endif %}
{% endif %}