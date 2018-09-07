require "rubygems"
require "bundler"
Bundler.require

require "sinatra/base"
require "rack/flash"

require 'cgi'


class MyFlashClass < Sinatra::Base
  configure do
    enable :sessions
    register Sinatra::Reloader
    use Rack::Flash
  end

  client = Mysql2::Client.new(:host => "localhost", :username => "root", :password => "root", :database => "GraduationWork")

  def check_boo
    if session[:user_id].nil?
      false
    else
      true
    end
  end

  # ↓ログインしていないと正常に動作しないページは、事前に↓をやる。
  def check
    if check_boo
    else
      redirect '/login'
    end
  end




  get '/top' do

    params[:go_msg] = nil
    params[:go_file] = nil

    check

    # === 自分についての情報 ===
    @my_user_id = session[:user_id]
    @my_user_name = "hogeさん"
    sql = "select * from users where id = #{@my_user_id};"
    sta = client.prepare(sql)
    sta.execute().each do |row|
      @my_user_name = row['user_name']
    end
    # === 自分についての情報 ここまで ===



    # === ツイートの読み込み。(そのユーザーと、フォローしているユーザーの投稿) ===
    sql = "select * from tweets where creater_id = #{session[:user_id]} OR (creater_id IN (select send from foll where who = #{session[:user_id]})) ORDER BY id DESC;"
    sta = client.prepare(sql)
    @res = sta.execute()
    # === ツイートの読み込みここまで ===



    # === フォロワー 情報の取得 5人まで===

    sql = "select * from users where id IN (select who from foll where send = #{session[:user_id]})  ORDER BY id ASC LIMIT 5;"
    sta = client.prepare(sql)
    @res_follower = sta.execute()

    # === フォロワー 情報の取得 ここまで ===
    # === フォロー 情報の取得 5人まで===

    sql = "select * from users where id IN ((select send from foll where who = #{session[:user_id]})) ORDER BY id ASC LIMIT 5;"
    sta = client.prepare(sql)
    @res_follow = sta.execute()

    # === フォロー 情報の取得 ここまで ===

    # === about_me で表示する情報を取得 ===
    # ツイート数・フォロー数・フォロワー数

    @count_follow = 0
    sql = "select count(who = #{session[:user_id]} or null) from foll;"
    sta = client.prepare(sql)
    sta.execute().each do |row|
      temp = "count(who = #{session[:user_id]} or null)"
      @count_follow = row["#{temp}"]
    end

    @count_follower = 0
    sql = "select count(send = #{session[:user_id]} or null) from foll;"
    sta = client.prepare(sql)
    sta.execute().each do |row|
      temp = "count(send = #{session[:user_id]} or null)"
      @count_follower = row["#{temp}"]
    end

    @count_tweet = 0
    sql = "select count(creater_id = #{session[:user_id]} or null) from tweets;"
    sta = client.prepare(sql)
    sta.execute().each do |row|
      temp = "count(creater_id = #{session[:user_id]} or null)"
      @count_tweet = row["#{temp}"]
    end

    # === about_me で表示する情報の取得 ここまで ===

    # ルーティングによって、animatedのアニメーションをオンオフしている。
    @animated_is = flash[:animated_is]

    erb :top
  end

  post '/top' do
    redirect '/top'
  end


  # === === マイページへ ===

  get '/mypage/:want_user_id' do

    check

    # その want_user_id がそもそも存在するのか。
    sta = client.prepare("select count(id or null) from users where id = #{params[:want_user_id]};")
    sta.execute().each do |row|
      if row['count(id or null)'].to_i == 0
        flash[:top_info] = "<p class='animated fadeInDown' id = 'flash_info' style='
          height: 34px;
          width: 30%;
          z-index: 2px;

          background-color: rgb(37, 165, 221);
          padding-left: 20px;

          margin: 6px 35% 10px 35%;
          border-radius: 5px;
          color: white;
          font-size: 1.5em;
          font-weight: solid;
          text-align: center;
        '>ユーザーが存在しません。</p>
          <style> #header_div { margin-top: -70px; } </style>"
        redirect '/top'
      end
    end

    # === 自分についての情報 ===
    @my_user_id = session[:user_id]
    @my_user_name = "hogeさん"
    sql = "select * from users where id = #{@my_user_id};"
    sta = client.prepare(sql)
    sta.execute().each do |row|
      @my_user_name = row['user_name']
    end
    # === 自分についての情報 ここまで ===

    # === 相手についての情報 ===
    @want_user_id = params[:want_user_id]
    @want_user_name = "hogeさん"
    sql = "select * from users where id = #{@want_user_id};"
    sta = client.prepare(sql)
    sta.execute().each do |row|
      @want_user_name = row['user_name']
    end
    # === 相手についての情報 ここまで===

    @page_res_title = "<span style='font-weight: bold; color: rgb(37, 165, 221);'>" + @want_user_name + "</span>"

    if @want_user_name === @my_user_name

      @hantei = "同じ"
      # === 自分のみ が投稿した ツイートを読み込む ===
      sql = "select * from tweets where creater_id = #{params[:want_user_id]} ORDER BY id DESC;"
      sta = client.prepare(sql)
      @res = sta.execute()
      # === 自分のみ が投稿した ツイートを読み込む ここまで ===

      # === 自分のマイページには、フォロワーボタンはつけない。===
      @mypage_follow_is = -1

    else

      @page_res_title = "<span style='font-weight: bold; color: rgb(37, 165, 221);'>" + @want_user_name + "</span>&nbsp;の投稿・<span style='font-weight: bold; color: rgb(37, 165, 221);'>フォローユーザー</span>"

      # === ツイートの読み込み。(そのユーザーと、フォローしているユーザーの投稿) ===
      sql = "select * from tweets where creater_id = #{@want_user_id} OR (creater_id IN (select send from foll where who = #{@want_user_id})) ORDER BY id DESC;"
      sta = client.prepare(sql)
      @res = sta.execute()
      # === ツイートの読み込みここまで ===

      # === my_user が want_user をフォロしているのか ===
      @mypage_follow_is = 0
      sql = "select * from foll where who = #{@my_user_id}"
      sta = client.prepare(sql)
      sta.execute().each do |row|
        if row['send'] == @want_user_id.to_i
          @mypage_follow_is = 1
        end
      end
      # === フォローしているのか。ここまで。===

    end


    # === フォロワー 情報の取得 全員 ===

    sql = "select * from users where id IN (select who from foll where send = #{@want_user_id})  ORDER BY id ASC;"
    sta = client.prepare(sql)
    @res_follower = sta.execute()

    # === フォロワー 情報の取得 ここまで ===
    # === フォロー 情報の取得 全員 ===

    sql = "select * from users where id IN ((select send from foll where who = #{@want_user_id})) ORDER BY id ASC;"
    sta = client.prepare(sql)
    @res_follow = sta.execute()

    # === フォロー 情報の取得 ここまで ===

    # === about_me で表示する情報を取得 ===
    # (ツイート数・フォロー数・フォロワー数)

    @count_follow = 0
    sql = "select count(who = #{@want_user_id} or null) from foll;"
    sta = client.prepare(sql)
    sta.execute().each do |row|
      temp = "count(who = #{@want_user_id} or null)"
      @count_follow = row["#{temp}"]
    end

    @count_follower = 0
    sql = "select count(send = #{@want_user_id} or null) from foll;"
    sta = client.prepare(sql)
    sta.execute().each do |row|
      temp = "count(send = #{@want_user_id} or null)"
      @count_follower = row["#{temp}"]
    end

    @count_tweet = 0
    sql = "select count(creater_id = #{@want_user_id} or null) from tweets;"
    sta = client.prepare(sql)
    sta.execute().each do |row|
      temp = "count(creater_id = #{@want_user_id} or null)"
      @count_tweet = row["#{temp}"]
    end

    @count_iine = 0
    sql = "select count(who = #{@want_user_id} or null) from iine;"
    sta = client.prepare(sql)
    sta.execute().each do |row|
      temp = "count(who = #{@want_user_id} or null)"
      @count_iine = row["#{temp}"]
    end

    # === about_me で表示する情報の取得 ここまで ===

    # === profile を取得 (登録処理もここで。) ===

    if session[:temp_comment].nil?
    else
      client.query("update users set user_profile = '#{session[:temp_comment]}' where id = #{session[:user_id]};")
    end

    sql = "select * from users where id = #{@want_user_id};"
    sta = client.prepare(sql)
    sta.execute().each do |row|
      @my_comment = row['user_profile']
    end

    # === profile を取得 ここまで ===


    # ルーティングによって、animatedのアニメーションをオンオフしている。
    @animated_is = flash[:animated_is]

    erb :mypage
  end

  # === === マイページへ ここまで ===


  # === === マイページの Ajax 処理 ===
  get '/mypage/ajax/:comment' do

    # button(id = profile_ajax)が押された際、myAjax.jsが動く。
    # jsからこのルーティングに飛んで、もう一回 js へ行く。

    session[:temp_comment] = CGI.escapeHTML(params[:comment]).gsub(/\r\n|\r|\n/, "<br />")

    content_type :json
    data = {comment: CGI.escapeHTML(params[:comment]).gsub(/\r\n|\r|\n/, "<br />")}
    data.to_json

  end
  # === === マイページの Ajax 処理 ここまで ===


# === === ログイン処理 ===

  get '/login' do
    if check_boo == true
      redirect '/top'
    end

    erb :login
  end

  post '/login' do

  # === 入された名前とパスワードがあっているのか判定。 ===
    sql = "select * from users where user_name = '#{params[:fo_name]}';"
    sta = client.prepare(sql)
    @res = sta.execute()

    login_status = false
    @res.each do |row|
      if row['user_pass'] == params[:fo_pass]
        login_status = true
        session[:user_id] = row['id']
      end
    end

    # === パスワードがあっていないか、そもそも該当する名前のレコードが存在しない場合はlogin_statusがfalseのまま。 ===
    if login_status == true
      flash[:top_info] = "<p class='animated fadeInDown' id = 'flash_info' style='
        height: 34px;
        width: 30%;
        z-index: 2px;

        background-color: rgb(37, 165, 221);
        padding-left: 20px;

        margin: 6px 35% 10px 35%;
        border-radius: 5px;
        color: white;
        font-size: 1.5em;
        font-weight: solid;
        text-align: center;
      '>ようこそ。</p>
        <style> #header_div { margin-top: -70px; } </style>"
      redirect '/top'
    else
      flash[:login_msg] = "<p class='animated fadeInDown' id = 'flash_info' style='
        height: 40px;
        background-color: rgba(221, 145, 14, 0.71);
        padding: 8px 15px;
        margin: 0 15px 25px 15px;
        border-radius: 5px;
        color: white;
        font-size: 1.7em;
        font-weight: solid;
      '>失敗：入力された情報に不備がありました。</p>"
      redirect '/login'
    end
  end

  # === === ログイン処理ここまで ===



  # === === ログアウト処理 ===
  get '/logout' do

    session[:user_id] = nil
    session[:temp_comment] = nil
    redirect '/top'

  end
  # === === ログアウト処理 ここまで===



  # === === アカウントの新規登録処理 ===
  # === 同じuser_nameは登録出来ないよにせねば。 ===

  get '/signup' do
    erb :signup
  end

  post '/signup' do
    sql = "select * from users where user_name = '#{params[:new_fo_name]}';"
    sta = client.prepare(sql)
    @res = sta.execute()

    kaburi = false
    @res.each do |row|
      kaburi = true
    end

    if kaburi
      flash[:signup_msg] = "<p class='animated fadeInDown' id = 'flash_info' style='
        height: 40px;
        background-color: rgba(32, 163, 65, 0.83);
        padding: 8px 15px;
        margin: 0 15px 25px 15px;
        border-radius: 5px;
        color: white;
        font-size: 1.7em;
        font-weight: solid;
      '>通知： 入力された名前は、既に使用されています。</p>"
      redirect '/signup'
    else

      # === 追加処理 ===

      # アカウントのアイコン画像を登録

      sql = "INSERT INTO users VALUES
      (NULL, '#{params[:new_fo_name]}', '#{params[:new_fo_pass]}', NULL);"
      sta = client.prepare(sql)
      @res = sta.execute()

      temp_id = 0
      sta = client.prepare("select * from users where user_name = '#{params[:new_fo_name]}';")
      sta.execute().each do |row|
        temp_id = row['id']
      end

      file = params[:new_icon_img][:tempfile]
      File.open("./public/user_icon/#{temp_id}_icon.jpg", 'wb') do |f|
        f.write(file.read)
      end

      # アカウントの背景画像を登録
      file = params[:new_back_img][:tempfile]
      File.open("./public/user_back/#{temp_id}_back.jpg", 'wb') do |f|
        f.write(file.read)
      end

      flash[:login_msg] = "<p class='animated fadeInDown' id = 'flash_info' style='
        height: 40px;
        background-color: rgba(48, 172, 199, 0.83);
        padding: 8px 15px;
        margin: 0 15px 25px 15px;
        border-radius: 5px;
        color: white;
        font-size: 1.7em;
        font-weight: solid;
      '>成功： 登録が無事処理されました。続けてログインして下さい。</p>"
      redirect '/login'
    end
  end
  # === === アカウントの新規登録処理ここまで ===




  # === === tweetsの追加処理 (リツイートは別。) ===

  post '/add_tweet' do

    go_msg = CGI.escapeHTML(params[:go_msg]).gsub(/\r\n|\r|\n/, "<br />")



    if params[:go_file]
      if params[:go_msg] != ""

        # "g_y, m_y"
        file_name = ((0..9).to_a + ("a".."z").to_a + ("A".."Z").to_a).sample(30).join
        file = params[:go_file][:tempfile]
        File.open("./public/imgs/" + file_name + ".jpg", 'wb') do |f|
          f.write(file.read)
        end

        sql = "INSERT INTO tweets VALUES(NULL, #{session[:user_id]}, CAST(now() as datetime), '#{go_msg}', '#{file_name}', NULL);"
        sta = client.prepare(sql)
        @res = sta.execute()

      else
        # "g_y, m_n"

        file_name = ((0..9).to_a + ("a".."z").to_a + ("A".."Z").to_a).sample(30).join
        file = params[:go_file][:tempfile]
        File.open("./public/imgs/" + file_name + ".jpg", 'wb') do |f|
          f.write(file.read)
        end

        sql = "INSERT INTO tweets VALUES(NULL, #{session[:user_id]}, CAST(now() as datetime), NULL, '#{file_name}', NULL);"

        p sql

        sta = client.prepare(sql)
        @res = sta.execute()

      end

      flash[:top_info] = "<p class='animated fadeInDown' id = 'flash_info' style='
        height: 34px;
        width: 30%;
        z-index: 2px;

        background-color: rgb(37, 165, 221);
        padding-left: 20px;

        margin: 6px 35% 10px 35%;
        border-radius: 5px;
        color: white;
        font-size: 1.5em;
        font-weight: solid;
      '>完了： 投稿が正常に処理されました。</p>
        <style> #header_div { margin-top: -70px; } </style>"

    else
      if params[:go_msg] != ""
        # "g_n, m_y"

        sql = "INSERT INTO tweets VALUES(NULL, #{session[:user_id]}, CAST(now() as datetime), '#{go_msg}', NULL, NULL);"
        sta = client.prepare(sql)
        @res = sta.execute()

        flash[:top_info] = "<p class='animated fadeInDown' id = 'flash_info' style='
          height: 34px;
          width: 30%;
          z-index: 2px;

          background-color: rgb(37, 165, 221);
          padding-left: 20px;

          margin: 6px 35% 10px 35%;
          border-radius: 5px;
          color: white;
          font-size: 1.5em;
          font-weight: solid;
        '>完了： 投稿が正常に処理されました。</p>
          <style> #header_div { margin-top: -70px; } </style>"

      else
        # "g_n, m_n"
      end
    end

    redirect '/top'
  end


  # === === tweet追加処理ここまで ===


  # === === フォロー ・ フォロワー の解除と登録 ===

  post '/foll_system' do

    if params[:delete_follow] == "フォロー中"
      sql = "delete from foll where who = #{session[:user_id]} AND send = #{params[:now_follow_id]};"
      sta = client.prepare(sql)
      @res = sta.execute()
    end

    if params[:add_follow] == "フォローする"
      sql = "INSERT INTO foll VALUES (NULL, #{session[:user_id]}, #{params[:now_unfollower_id]});"
      sta = client.prepare(sql)
      @res = sta.execute()
    end

    @url = params[:from_url]
    redirect "#{@url}"
  end

  # === === フォロー ・ フォロワー の解除と登録 ここまで===

  # === === 画像の変更 ===

  post '/edit_img_back' do
    file = params[:go_img_back][:tempfile]
    File.open("./public/user_back/#{session[:user_id]}_back.jpg", 'w+b') do |f|
      f.write(file.read)
    end
    redirect "#{params[:from_url]}"
  end

  post '/edit_img_icon' do
    file = params[:go_img_icon][:tempfile]
    File.open("./public/user_icon/#{session[:user_id]}_icon.jpg", 'w+b') do |f|
      f.write(file.read)
    end
    redirect "#{params[:from_url]}"
  end

  # === === 画像の変更 ここまで ===


  # === === いいね の登録・解除 処理 ===
  post '/iine_system' do
    if params[:iine_on]
      client.query("insert into iine values (NULL, #{session[:user_id]}, #{params[:twe_id]});")
    elsif params[:iine_off]
      client.query("delete from iine where who = #{session[:user_id]} and twe_id = #{params[:twe_id]};")
    end

    # このルーティングを通った場合、animatedのアニメーションをoff
    flash[:animated_is] = "nya"

    # === redirect で元の投稿の表示部分へ戻そうとしている。 ===
    # 上の投稿が画像なら、それを表示させる。
    if params[:pre_img_is] == "true"
      # ただ、自分が画像持っているなら、自分を表示。
      if params[:my_img_is] == "true"
        redirect "#{params[:from_url]}#res_num_#{params[:res_num].to_i - 0}"
      else
        redirect "#{params[:from_url]}#res_num_#{params[:res_num].to_i - 1}"
      end
    else
      # 上が画像でない。なら、2 か 1 つ前の投稿を表示させる。 迷っている。
      redirect "#{params[:from_url]}#res_num_#{params[:res_num].to_i - 2}"
    end
  end
  # === redirect の記述 ここまで。 ===


  # === === いいね の登録・解除 処理 ここまで ===


  # === === いいね の Ajax 処理 ===
  # 追記： resultが、全ての方に出力されてしまうので、めんどう。
  # get '/iine/ajax/:text_msg' do
  #
  #   # session[:iine_ajax_is] = true
  #
  #   puts "hello"
  #   puts params[:iine]
  #
  #   content_type :json
  #   data = {text: params[:text_msg]}
  #   data.to_json
  #
  # end
  # === === いいね の Ajax 処理 ここまで ===


  # === === リツイート の登録処理 ===

  post '/retw_system' do

    if params[:retw_on]
      client.query("insert into tweets values(NULL, #{session[:user_id]}, CAST(now() as datetime), NULL, NULL, #{params[:twe_id]});")
    end

    # このルーティングを通った場合、animatedのアニメーションをoff
    flash[:animated_is] = "nya"

    # === redirect で元の投稿の表示部分へ戻そうとしている。 ===
    # 上の投稿が画像なら、それを表示させる。
    if params[:pre_img_is] == "true"
      # ただ、自分が画像持っているなら、自分を表示。
      if params[:my_img_is] == "true"
        redirect "#{params[:from_url]}#res_num_#{params[:res_num].to_i - 0}"
      else
        redirect "#{params[:from_url]}#res_num_#{params[:res_num].to_i - 1}"
      end
    else
      # 上が画像でない。なら、2 か 1 つ前の投稿を表示させる。 迷っている。
      redirect "#{params[:from_url]}#res_num_#{params[:res_num].to_i - 2}"
    end

  end

  # === === リツイート の登録処理 ここまで ===


  get '/' do
    check
    redirect '/top'
  end
  get '/mypage' do
    check
    redirect "/mypage/#{session[:user_id]}"
  end
  get '/mypage/' do
    check
    redirect "/mypage/#{session[:user_id]}"
  end


  # 試作ページ用

  get '/serch' do
    erb :serch_out
  end

  # 試作ページ用 ここまで



end
