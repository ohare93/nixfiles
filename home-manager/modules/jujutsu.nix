{
  inputs,
  ...
}: {
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        inherit (inputs.private.identity) email;
        name = inputs.private.identity.fullName;
      };
      git = {
        private-commits = "description(glob:'private:*')";
        # Jujutsu respects git's global gitignore automatically
        # Additional patterns can be added here if needed
      };
      ui = {
        default-command = ["log" "-r" "trunk()..@ | trunk() | @.. "];
        paginate = "auto";
        editor = "nvim";
      };
      template-aliases = {
        # Just the shortest possible unique prefix
        "format_short_id(id)" = "id.shortest()";
        # Relative timestamp rendered as "x days/hours/seconds ago"
        "format_timestamp(timestamp)" = "timestamp.ago()";
        # Username part of the email address
        "format_short_signature(signature)" = "signature.email().local()";
      };
      revset-aliases = {
        "immutable_heads()" = ''trunk() | (trunk().. & ~mine() & ~author(substring:"noreply@anthropic.com")) | untracked_remote_bookmarks() | (tags() & ~tags(regex:".*-feature.*"))'';
      };
    };
  };
}
