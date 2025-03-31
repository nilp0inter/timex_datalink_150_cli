{
  activemodel = {
    dependencies = ["activesupport"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "10qaykhcs15wgyy9fd886mwdkf3iwsib0h6fcnwqa7jw0nxh8fzi";
      type = "gem";
    };
    version = "7.0.8.7";
  };
  activesupport = {
    dependencies = ["concurrent-ruby" "i18n" "minitest" "tzinfo"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1zq4f834my1z6yh05rfr1dzl3i8padh33j092zlal979blvh4iyz";
      type = "gem";
    };
    version = "7.0.8.7";
  };
  concurrent-ruby = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1ipbrgvf0pp6zxdk5ascp6i29aybz2bx9wdrlchjmpx6mhvkwfw1";
      type = "gem";
    };
    version = "1.3.5";
  };
  crc = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1qns4v7gjac9jb9f33sx8wlq56hk5139sl8qxjq5c4f1i462nhv6";
      type = "gem";
    };
    version = "0.4.2";
  };
  i18n = {
    dependencies = ["concurrent-ruby"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "03sx3ahz1v5kbqjwxj48msw3maplpp2iyzs22l4jrzrqh4zmgfnf";
      type = "gem";
    };
    version = "1.14.7";
  };
  mdb = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "15ynqlf3qmgdb4bsgsz6jx8b0hq4q38b587xrlg5mxm9v5s2adfb";
      type = "gem";
    };
    version = "0.5.0";
  };
  minitest = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0izrg03wn2yj3gd76ck7ifbm9h2kgy8kpg4fk06ckpy4bbicmwlw";
      type = "gem";
    };
    version = "5.25.4";
  };
  ruby-termios = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0xgk1z9csanlj313hqig9f545d5y7w5m8cmbxf0xl9scsqc3ynyh";
      type = "gem";
    };
    version = "1.1.0";
  };
  timex_datalink_client = {
    dependencies = ["activemodel" "crc" "mdb" "uart"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1lf69cx5kn4rhgrn28jany910dfd0vi22gnp784bzdxmv1d9rbw0";
      type = "gem";
    };
    version = "0.12.4";
  };
  tzinfo = {
    dependencies = ["concurrent-ruby"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "16w2g84dzaf3z13gxyzlzbf748kylk5bdgg3n1ipvkvvqy685bwd";
      type = "gem";
    };
    version = "2.0.6";
  };
  uart = {
    dependencies = ["ruby-termios"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "13qid15w8zhx7fkgraii5nxcrqiz928plchzwvy7q5bnqmg5iv4r";
      type = "gem";
    };
    version = "1.0.0";
  };
}
