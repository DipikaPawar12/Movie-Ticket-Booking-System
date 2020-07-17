from flask import Flask,render_template,flash,request,redirect,url_for,session,logging
from flask_mysqldb import MySQL
from flask_table import Table, Col
from wtforms import Form, StringField, TextAreaField, PasswordField, validators,DateField,TimeField,DecimalField,IntegerField , RadioField, SelectMultipleField,widgets
from passlib.hash import sha256_crypt
from datetime import date,time,datetime,timedelta;
import  datetime as dt
from functools import wraps
import json
import matplotlib.pyplot as plt
import numpy as np
import  pdfkit


trail= Flask(__name__)

#for mysql setup
trail.config['MYSQL_HOST'] = 'localhost'            #local host name
trail.config['MYSQL_USER'] = 'root'                 #your user name
trail.config['MYSQL_PASSWORD'] = ''                 #your password
trail.config['MYSQL_DB'] = 'movie'                  #Your database name
trail.config['MYSQL_CURSORCLASS'] = 'DictCursor'

# init MYSQL
mysql = MySQL(trail)


# for convert html page to pdf ... AT this moment not working
path_wkhtmltopdf = r'F:\PythonProgram\Airport_Management\wkhtmltopdf\bin\wkhtmltopdf.exe'
config = pdfkit.configuration(wkhtmltopdf=path_wkhtmltopdf)
pdfkit.from_url("http://google.com", "out.pdf", configuration=config)


#Home page url and function
@trail.route('/')
def index():
    return render_template('homeAgain.html')

""" Admin Login method:
    - fetch data from login page username and password
    - if login credentials metch them go to admin dash board (dash.html)
    - else in all condition render the same page
"""
@trail.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']                                             #retrive username and password
        password_candidate = request.form['password']
        cur = mysql.connection.cursor()
        result = cur.execute("SELECT * FROM admin WHERE username = %s", [username])     # fetch the data stored in admin table
        if result > 0:
            data = cur.fetchone()
            password = sha256_crypt.encrypt(data['password'])                           # encrypt password to match excatly with db password
            if sha256_crypt.verify(password_candidate, password):
                session['logged_in'] = True
                session['username'] = username
                flash('You are now logged in', 'success')
                return redirect(url_for('dash'))
            else:
                error = 'Invalid login'
                return render_template('login.html', error=error)
            # Close connection
            cur.close()
        else:
            error = 'Username not found'
            return render_template('login.html', error=error)

    return render_template('login.html')

""" Alow function only admin logged in... not working here """
def is_logged_in(f):
    @wraps(f)
    def wrap(*args, **kwargs):
        if 'logged_in' in session:
            return f(*args, **kwargs)
        else:
            flash('Unauthorized, Please login', 'danger')
            return redirect(url_for('login'))
    return wrap

# Load dashboard for admin in which one can do crud operation on
# Movie and Combo also see some reports
@trail.route('/dash')
def dash():
    return render_template('dash.html')

"""
CRUD: operation on movie
i)Movie add to theater.
class of moview register
class for checkbox field
"""

class MultiCheckboxField(SelectMultipleField):
    widget = widgets.ListWidget(prefix_label=False)
    option_widget = widgets.CheckboxInput()

# Movie Register Form Class
class RegisterForm(Form):
    string_of_files = ['Romantic\r\nAction\r\nComedy\r\nDrama\r\nHorror\r\nAdult\r\nFiction\r\nNon-Fiction']
    list_of_files = string_of_files[0].split()
    # create a list of value/description tuples
    files = [(x, x) for x in list_of_files]

    string_of_files1 = ['English\r\nHindi']
    list_of_files1 = string_of_files1[0].split()
    # create a list of value/description tuples
    files1 = [(x, x) for x in list_of_files1]

    string_of_files2 = ['Released\r\nUpcoming\r\nPast']
    list_of_files2 = string_of_files2[0].split()
    # create a list of value/description tuples
    files2 = [(x, x) for x in list_of_files2]

    #All the necessary field for movie table
    movieName = StringField('Name:', [validators.Length(min=1, max=40)])
    movieDiscription = TextAreaField('Description:', [validators.Length(min=20, max=150)])
    movieDirector = StringField('Director:', [validators.Length(min=1, max=30)])
    movieProducer = StringField('Producer:', [validators.Length(min=1, max=30)])
    movieGenre =MultiCheckboxField('Genre:', choices=files)
    castName = TextAreaField('Cast Name(s):', [validators.Length(min=1, max=200)])
    movieCertificate = StringField('Certificate(U/A/UA):', [validators.Length(min=1, max=10)])
    movieDuration = TimeField('Duration(HH-MM-SS):', format='%H:%M:%S')
    movieRating = DecimalField('Rating(1-5):', places=2, rounding=None, use_locale=False, number_format=None)
    movieReleaseDate =  DateField('Release Date(YYYY-MM-DD):', format='%Y-%m-%d')
    movieLanguage= MultiCheckboxField('Language:', choices=files1)
    movieStatus=MultiCheckboxField('Status:', choices=files2)

# Movie Register to database
@trail.route('/register', methods=['GET', 'POST'])
def register():
    form = RegisterForm(request.form)
    error=''
    if request.method == 'POST' and form.validate():
        #print("yes")
        movieName = form.movieName.data
        movieDiscription = form.movieDiscription.data
        movieDirector = form.movieDirector.data
        movieProducer = form.movieProducer.data
        movieGenre = form.movieGenre.data
        movieCertificate  = form.movieCertificate.data
        movieDuration = form.movieDuration.data
        movieRating = (form.movieRating.data)
        movieReleaseDate = form.movieReleaseDate.data
        movieLanguage = form.movieLanguage.data
        movieStatus = form.movieStatus.data
        status=0

        # These all ifs are for error showing like in case user didn't select any field  from
        # checkbox or checked multiple fields from it
        if (len(movieGenre)==0):
            status=1
            error+='Please select one genre. \n'
        if(len(movieLanguage)==0):
            status=1
            error += 'Please select one language. \n'

        if (len(movieStatus) == 0):
            status = 1
            error += 'Please select one Status of movie. \n'


        if (len(movieGenre)>1):
            status=1
            error+='cant not choose multiple genre. \n'
        if(len(movieLanguage)>1):
            status=1
            error+= 'can not choose multiple language. \n'
        if (len(movieStatus) > 1):
            status = 1
            error += 'can not choose multiple movie Status. \n'
        if status==1:
            return render_template('register.html', form=form,error=error)

        else:
            err=''
            flag=0
            try:
                cur = mysql.connection.cursor()
                # Enter data in movie table
                cur.execute("INSERT INTO movie VALUES (NULL, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NULL)",
                            ( movieName, movieDiscription, movieDirector, movieProducer, movieGenre, movieCertificate, movieDuration, movieRating, movieReleaseDate, movieLanguage, movieStatus ))
                mysql.connection.commit()

                castName=form.castName.data
                l=list(castName.split(','))
                #enter data in movieCast table 
                cur.execute("select movieId from movie where movieName=%s",[movieName])
                id=cur.fetchone()
                for i in range(len(l)):
                    cur.execute("INSERT INTO moviecast Values(%s,%s)",(id['movieId'],l[i]))
                    mysql.connection.commit()
                cur.close()
                print(movieStatus)
                flash('You are now registered and can log in', 'success')
                if movieStatus == ['Released']:
                    return redirect(url_for('movieStatus',movieId=id['movieId']))
                else:
                    return redirect(url_for('dash'))
            except Exception as e:
                return  render_template('movieExcept.html',err=e)

    return render_template('register.html', form=form,error=error)

# Class to add time slot on which time movie should be played
class TimeRegisterForm(Form):
    string_of_files1 = ['True\r\nFalse']
    list_of_files1 = string_of_files1[0].split()
    # create a list of value/description tuples
    files1 = [(x, x) for x in list_of_files1]

    string_of_files = ['1\r\n2']
    list_of_files = string_of_files[0].split()
    # create a list of value/description tuples
    files = [(x, x) for x in list_of_files]

    slotTheaterId = MultiCheckboxField('slotTheaterId', choices=files)
    slotScreenId = MultiCheckboxField('slotScreenId', choices=files)
    time1 = MultiCheckboxField('9:30', choices=files1)
    time2 = MultiCheckboxField('2:30', choices=files1)
    time3 = MultiCheckboxField('8:00', choices=files1)

# method for register time slot
@trail.route('/movieStatus/<int:movieId>', methods=['GET', 'POST'])
def movieStatus(movieId):
    form = TimeRegisterForm(request.form)
    form1= SlotAdd(request.form)
    error = ''
    if request.method == 'POST' and form.validate():
        slotTheaterId = form.slotTheaterId.data
        slotScreenId = form.slotScreenId.data
        time1 = form.time1.data
        time2 = form.time2.data
        time3 = form.time3.data
        status=0

        #print(len(time1))
        if len(slotTheaterId)==0:
            status=1
            error+='Please select from theater. \n'
        if len(slotScreenId)==0:
            status=1
            error+='Please select from screen. \n'

        if len(slotTheaterId)==2:
            status=1
            error+='you can not select both theater. \n'
        if len(slotScreenId)==2:
            status=1
            error+='you can not select both screen. \n'

        if len(time1)==0:
            status=1
            error+='Please select from time1. \n'
        if len(time2)==0:
            status=1
            error+='Please select from time2. \n'
        if len(time3)==0:
            status=1
            error+="Please select from time3. \n"

        if len(time1)==2:
            status=1
            error+="You can not select both from time1. \n"
        if len(time2)==2:
            status=1
            error+="You can not select both from time2. \n"
        if len(time3)==2:
            status=1
            error+="You can not select both from time3. \n"

        if status==1:
            return render_template('movieStatus.html',form=form,error=error)
        else:
            flag=0
            err=""
            try:
                cur = mysql.connection.cursor()
                cur.execute("INSERT INTO timmingofmovie VALUES (%s, %s, %s, %s, %s, %s)",(movieId,slotTheaterId,slotScreenId,time1,time2,time3))
                mysql.connection.commit()
                cur.close()
            except Exception as e:
                err=e
                flag=1
            if flag==0:
                return redirect(url_for('slotAdd',movieId=movieId))
            else:
                return  render_template("slotAddExcep.html",error=err,movieId=movieId)
    return render_template('movieStatus.html',form=form,error=error)


# class to ask admin to add more slots 
class SlotAdd(Form):
    wantMore = StringField('wantMore', [validators.Length(min=2, max=3)])

# render page according to admin's yes/no choice
@trail.route('/slotAdd/<int:movieId>', methods=['GET', 'POST'])
def slotAdd(movieId):
    form= SlotAdd(request.form)
    if request.method == 'POST' and form.validate():
        wantmore=form.wantMore.data
        if wantmore=='yes' or wantmore=='YES':
            return redirect(url_for('movieStatus', movieId=movieId))
        else:
            return  redirect(url_for('dash'))
    return  render_template('slotAdd.html',form=form)


@trail.route('/movieDetail/<int:slotMovieId>/<int:slotMovietheaterId>', methods=['POST'])
def movieDetail(slotMovieId,slotTheaterId):
    cur = mysql.connection.cursor()
    cur.execute("DELETE FROM movie WHERE movieId = %s", [movieId])
    mysql.connection.commit()
    cur.close()
    flash('MovieDeleted', 'success')

    return redirect(url_for('dash'))

# Shows a table of movie detail  sorry for this naming convention
@trail.route('/deleteMovie', methods=['GET', 'POST'])
@is_logged_in
def deleteMovie():

    cur = mysql.connection.cursor()
    result = cur.execute("SELECT * FROM movie")
    if result > 0:
        data = cur.fetchall()
        cur.close()
        return render_template('deleteMovie.html',value=data)

    return render_template('deleteMovie.html')

# Edit movie details with movie Id given from deleteMovie function 
@trail.route('/editmovie/<int:movieId>', methods=['GET', 'POST'])
@is_logged_in
def editmovie(movieId):
    cur = mysql.connection.cursor()
    result = cur.execute("SELECT * FROM movie WHERE movieId = %s", [movieId])
    movie = cur.fetchone()
    cur.close()
    form = RegisterForm(request.form)
    form.movieName.data=movie['movieName']
    form.movieDiscription.data = movie['movieDiscription']
    form.movieDirector.data = movie['movieDirector']
    form.movieProducer.data = movie['movieProducer']
    form.movieGenre.data = movie['movieGenre']
    form.movieCertificate.data = movie['movieCertificate']
    form.movieDurationdata =  movie['movieDuration']
    form.movieRating.data = movie['movieRating']
    form.movieReleaseDate.data = movie['movieReleaseDate']
    form.movieLanguage.data = movie['movieLanguage']
    form.movieStatus.data = movie['movieStatus']

    if request.method == 'POST' and form.validate():
        movieName = request.form['movieName']
        movieDiscription =  request.form['movieDiscription']
        movieDirector =  request.form['movieDirector']
        movieProducer =  request.form['movieProducer']
        movieGenre =  request.form['movieGenre']
        movieCertificate  =  request.form['movieCertificate']
        movieDuration =  request.form['movieDuration']
        movieRating =  request.form['movieRating']
        movieReleaseDate =  request.form['movieReleaseDate']
        movieLanguage =  request.form['movieLanguage']
        movieStatus =  request.form['movieStatus']
        cur = mysql.connection.cursor()
        trail.logger.info(movieName)
        cur.execute("UPDATE movie SET movieName=%s,movieDiscription=%s, movieDirector=%s, movieProducer=%s, movieGenre=%s, movieCertificate=%s, movieDuration=%s, movieRating=%s, movieReleaseDate= %s,movieLanguage=%s, movieStatus=%s WHERE movieId=%s",
                    ( movieName, movieDiscription, movieDirector, movieProducer, movieGenre, movieCertificate, movieDuration, movieRating, movieReleaseDate, movieLanguage, movieStatus,[movieId ]))
        mysql.connection.commit()
        cur.close()

        flash('record updated', 'success')
        return redirect(url_for('deleteMovie'))
    return render_template('edit_movie.html', form=form)


# Delete movie with movie Id given from deleteMovie function
@trail.route('/delete_movie/<int:movieId>', methods=['POST'])
@is_logged_in
def delete_movie(movieId):
    #print(movieId)
    cur = mysql.connection.cursor()
    cur.execute("DELETE FROM movie WHERE movieId = %s", [movieId])
    mysql.connection.commit()
    cur.close()

    flash('MovieDeleted', 'success')

    return redirect(url_for('dash'))


"""
Combo register in each theater method and requiered fields as a class
 """
class ComboRegisterForm(Form):
    comboId = DecimalField('comboId', places=0, rounding=None, use_locale=False, number_format=None)
    comboTheaterId = DecimalField('comboTheaterId', places=0, rounding=None, use_locale=False, number_format=None)
    comboName = StringField('comboName', [validators.Length(min=1, max=30)])
    comboPrice = DecimalField('comboPrice', places=0, rounding=None, use_locale=False, number_format=None)
    comboQuantity = DecimalField('comboQauntity', places=0, rounding=None, use_locale=False, number_format=None)
    comboDiscription = TextAreaField('comboDiscription', [validators.Length(min=20, max=150)])

# Combo Register
@trail.route('/comboRegister', methods=['GET', 'POST'])
@is_logged_in
def comboRegister():
    form = ComboRegisterForm(request.form)
    if request.method == 'POST' and form.validate():
        comboId = form.comboId.data
        comboTheaterId =  form.comboTheaterId.data
        comboName = form.comboName.data
        comboPrice = form.comboPrice.data
        comboQuantity = form.comboQuantity.data
        comboDiscription = form.comboDiscription.data
        flag=0
        error=""
        try:
            cur = mysql.connection.cursor()
            cur.execute("INSERT INTO combo VALUES ( %s, %s, %s, %s, %s, %s)",( comboId,comboTheaterId ,comboName,comboPrice ,comboQuantity , comboDiscription ))
            mysql.connection.commit()
            cur.close()
        except Exception as e:
            flag=1
            error=e
        if flag==1:
            return  render_template("comboExcept.html",error=error)
        else:
            return redirect(url_for('dash'))
    return render_template('comboRegister.html', form=form)

# shows combo list 
@trail.route('/comboList', methods=['GET', 'POST'])
@is_logged_in
def comboList():
    cur = mysql.connection.cursor()
    result = cur.execute("SELECT * FROM combo")
    if result > 0:
        data = cur.fetchall()
        cur.close()
        return render_template('comboList.html',value=data)
    return render_template('comboList.html')

# Delete combo from the list
@trail.route('/delete_combo/<int:comboId>/<int:comboTheaterId>', methods=['POST'])
@is_logged_in
def delete_combo(comboId,comboTheaterId):
    cur = mysql.connection.cursor()
    cur.execute("DELETE FROM combo WHERE comboId = %s and comboTheaterId=%s",( [comboId],[comboTheaterId]))
    mysql.connection.commit()
    cur.close()
    flash('ComboDeleted', 'success')
    return redirect(url_for('dash'))

# edit combo details
@trail.route('/editcombo/<int:comboId>/<int:comboTheaterId>', methods=['GET', 'POST'])
@is_logged_in
def editcombo(comboId,comboTheaterId):
    cur = mysql.connection.cursor()
    result = cur.execute("SELECT * FROM combo WHERE comboId = %s and comboTheaterId=%s", ([comboId],[comboTheaterId]))
    combo = cur.fetchone()
    cur.close()
    form = ComboRegisterForm(request.form)
    #print(combo)
    form.comboId.data=combo['comboId']
    form.comboTheaterId.data=combo['comboTheaterId']
    form.comboName.data=combo['comboName']
    form.comboPrice.data=combo['comboPrice']
    form.comboQuantity.data=combo['comboQuantity']
    form.comboDiscription.data = combo['comboDiscription']
    if request.method == 'POST' and form.validate():
        comboId = request.form['comboId']
        comboTheaterId = request.form['comboTheaterId']
        comboName = request.form['comboName']
        comboPrice = request.form['comboPrice']
        comboQuantity = request.form['comboQuantity']
        comboDiscription = request.form['comboDiscription']
        cur = mysql.connection.cursor()

        cur.execute("UPDATE combo SET comboId= %s,comboTheaterId= %s,comboName= %s,comboPrice= %s, comboQuantity=%s,comboDiscription= %s WHERE comboId=%s and comboTheaterId=%s",
                    (comboId, comboTheaterId, comboName, comboPrice, comboQuantity, comboDiscription,comboId,comboTheaterId))
        #print("UPDATE combo SET comboId= %s,comboTheaterId= %s,comboName= %s,comboPrice= %s, comboQuantity=%s,comboDiscription= %s WHERE comboId=%s and comboTheaterId=%s",
              #      (comboId, comboTheaterId, comboName, comboPrice, comboQuantity, comboDiscription,comboId,comboTheaterId))
        mysql.connection.commit()
        cur.close()

        flash('Combo is edited', 'success')
        return redirect(url_for('comboList'))
    return render_template('editCombo.html', form=form)

"""
Here is 5 reports whose data is generated by function or procedure in SQL
 """
# Chart which shoes number of viewer vs movie which are currently in theater
@trail.route('/report', methods=['GET', 'POST'])
def report():
    cur = mysql.connection.cursor()
    cur.callproc('noUserMovie')
    st=cur.fetchall()
    cur.close()
    l = list(st[0]['name'].split(";"))
    l.pop()
    for i in range(0, len(l)):
        l[i] = list(l[i].split("="))
    x=['d']*len(l)
    y=[0]*len(l)
    for i in range(len(l)):
        x[i]=l[i][0]
        y[i]=int(l[i][1])

    plt.bar(x, y)
    plt.ylabel('Number of viwers')
    plt.xlabel('Movie Name')
    plt.show()
    return redirect(url_for('dash'))

# Chart of number of viewer of movie (seven day per movie)
@trail.route('/report2', methods=['GET', 'POST'])
def report2():


    cur = mysql.connection.cursor()
    cur.callproc('movieWeekly')
    st=cur.fetchall()
    print(st)
    cur.close()
    l = list(st[0]['name'].split("+"))
    l.pop()
    lb=["f"]*len(l)
    for i in range(0, len(l)):
        l[i] = list(l[i].split("="))
    for i in range(0, len(l)):
        lb[i]=l[i][0]
        l[i][1] = list(l[i][1].split(";"))
        l[i][1].pop()

    a = [[0 for i in range(len(l))] for j in range(7)]
    #date = [[1]*7]*len(l)
    for i in range( len(l)):
        for j in range(len(l[i][1])):
            l[i][1][j]=list(l[i][1][j].split(","))
    #print(l)
    for i in range(0, len(l)):
        k = 0
        d1 = dt.datetime.strptime("1973-01-23", "%Y-%m-%d")
        d1 = d1.date()
        for j in range(0, len(l[i][1])):

            if j != 0:
                d2 = dt.datetime.strptime(l[i][1][j][1], "%Y-%m-%d")
                d2 = d2.date()
                diff = (d2 - d1).days
                k += diff - 1
                #print(k)
            a[k][i] = int(l[i][1][j][0])
            k += 1
            d1 = dt.datetime.strptime(l[i][1][j][1], "%Y-%m-%d")
            d1 = d1.date()

    #print(a)
    n_groups = len(l)

    # create plot
    fig, ax = plt.subplots()
    index = np.arange(n_groups)
    bar_width = 0.125
    opacity = 1

    rects1 = plt.bar(index, a[0], bar_width,
                     alpha=opacity,
                     color='r',
                     label='Day1')

    rects2 = plt.bar(index+0.125, a[1], bar_width,
                     alpha=opacity,
                     color='b',
                     label='Day2')
    rects3 = plt.bar(index+0.25, a[2], bar_width,
                     alpha=opacity,
                     color='g',
                     label='Day3')

    rects4 = plt.bar(index+0.25+0.125 , a[3], bar_width,
                     alpha=opacity,
                     color='y',
                     label='Day4')
    rects5 = plt.bar(index+0.5, a[4], bar_width,
                     alpha=opacity,
                     color='k',
                     label='Day5')

    rects6 = plt.bar(index+0.5+0.125, a[5], bar_width,
                     alpha=opacity,
                     color='c',
                     label='Day6')
    rects7 = plt.bar(index+0.75,a[6], bar_width,
                     alpha=opacity,
                     color='m',
                     label='Day7')

    plt.xlabel('Movie Name')
    plt.ylabel('Viewers')
    plt.title('Day wise movie collection')
    plt.xticks(index + bar_width, lb)
    plt.legend()
    plt.tight_layout()
    plt.show()
    return redirect(url_for('dash'))

# PDF of daily number of visitor theater wise
@trail.route('/report3', methods=['GET', 'POST'])
def report3():
    cur = mysql.connection.cursor()
    cur.execute('SELECT dailyTheaterVisiter() ')
    st=cur.fetchone()
    #print(st)
    cur.close()
    l = list(st['dailyTheaterVisiter()'].split("+"))

    for i in range(len(l)):
        l[i] = list(l[i].split(";"))
        l[i].pop()

    for i in range(len(l)):
        for j in range(len(l[i])):
            l[i][j]=list(l[i][j].split(","))


    return  render_template("report3.html",value=l)

# PDF of number of visitor from the first day to till today theater wise
@trail.route('/report4', methods=['GET', 'POST'])
def report4():
    cur = mysql.connection.cursor()
    cur.execute('SELECT historyTheaterVisiter() ')
    st=cur.fetchone()
    #print(st)
    cur.close()
    l = list(st['historyTheaterVisiter()'].split("+"))
    for i in range(len(l)):
        l[i] = list(l[i].split(";"))
        l[i].pop()

    for i in range(len(l)):
        for j in range(len(l[i])):
            l[i][j] = list(l[i][j].split("/"))
    for i in range(len(l)):
        for j in range(len(l[i])):
            l[i][j][1] = list(l[i][j][1].split(","))
            l[i][j][1].pop()
    for i in range(len(l)):
        for j in range(len(l[i])):
            for k in range(len(l[i][j][1])):
                l[i][j][1][k] = list(l[i][j][1][k].split("#"))


    return render_template('report4.html',value=l)

# PDF of theater daily sale on movies and combo theater wise 
@trail.route('/report5', methods=['GET', 'POST'])
def report5():
    cur = mysql.connection.cursor()
    cur.execute('SELECT theaterSale() ')
    st=cur.fetchone()
    print(st)
    l=list(st['theaterSale()'].split('+'))
    l[0]=list(l[0].split(','))
    l[1] = list(l[1].split(','))
    l.pop()
    tt1=0
    tt2=0
    ct1=0
    ct2=0
    if(l[0][0]==''):
        tt1=0
        ct1=0
    else:
        tt1 = int(l[0][0])
    if(l[1][0]==''):
        tt1=0
        ct1=0
    else:
        tt2 = int(l[1][0])
    if(l[0][1]==''):
        ct1=0
    else:
        ct1=int(l[0][1])
    if(l[1][1]==''):
        ct2=0
    else:
        ct2=int(l[1][1])
    #print(l)
    return render_template('report5.html',tt1=tt1,tt2=tt2,ct1=ct1,ct2=ct2)

# Not needed
@trail.route('/call_find_all_sp', methods=['GET', 'POST'])
def call_find_all_sp():
    cur = mysql.connection.cursor()
    cur.callproc('moviecusor',(None))
    print(cur.fetchall())
    cur.close()
    return render_template('dash.html')


""" 
Now for user side
user front screen shows available movie and with search bar facility
"""
# take input of search bar and pass to /user method
class Search(Form):
    search = StringField('search',[validators.Length(min=0, max=30)])
    string_of_files3 = ['movieName\r\nmovieRating\r\nmovieLanguage']
    list_of_files3 = string_of_files3[0].split()
    # create a list of value/description tuples
    files3 = [(x, x) for x in list_of_files3]
    pro = MultiCheckboxField('Sort by:', choices=files3)

# shows available movie on screen
@trail.route('/user', methods=['GET', 'POST'])
def user():
    form = Search(request.form)
    cur = mysql.connection.cursor()
    if request.method == 'POST' and form.validate():
        s = form.search.data
        pr=form.pro.data
        likeString = "%" + s+ "%"
       # different situation depend on search item
        if(len(pr)==0):
            result = cur.execute("SELECT DISTINCT movieId,movieName, theaterId,theaterName,movieReleaseDate,movieRating,movieLanguage from movie,timmingofmovie,theater where lower(movieName) LIKE %s and movieStatus='Released' and movieId = slotMovieId and theaterId = slotTheaterId ",([likeString]))
        elif(len(pr)==1):
            if pr==['movieName']:
                result = cur.execute("SELECT DISTINCT movieId,movieName, theaterId,theaterName,movieReleaseDate,movieRating,movieLanguage from movie,timmingofmovie,theater where lower(movieName) LIKE %s and movieStatus='Released' and movieId = slotMovieId and theaterId = slotTheaterId order by movieName",([likeString]))
            elif pr==['movieRating']:
                result = cur.execute("SELECT DISTINCT movieId,movieName, theaterId,theaterName,movieReleaseDate,movieRating,movieLanguage from movie,timmingofmovie,theater where lower(movieName) LIKE %s and movieStatus='Released' and movieId = slotMovieId and theaterId = slotTheaterId order by movieRating",([likeString]))
            else:
                result = cur.execute("SELECT DISTINCT movieId,movieName, theaterId,theaterName,movieReleaseDate,movieRating,movieLanguage from movie,timmingofmovie,theater where lower(movieName) LIKE %s and movieStatus='Released' and movieId = slotMovieId and theaterId = slotTheaterId order by movieLanguage",([likeString]))
        else:
            result = cur.execute("SELECT DISTINCT movieId,movieName, theaterId,theaterName,movieReleaseDate,movieRating,movieLanguage from movie,timmingofmovie,theater where lower(movieName) LIKE %s and movieStatus='Released' and movieId = slotMovieId and theaterId = slotTheaterId ",([likeString]))
    else:
        result = cur.execute("SELECT DISTINCT movieId,movieName, theaterId,theaterName,movieReleaseDate,movieRating,movieLanguage from movie,timmingofmovie,theater where movieId = slotMovieId and movieStatus='Released' and theaterId = slotTheaterId order by movieId")
    #print(result)
    if result > 0:
        data = cur.fetchall()
        cur.close()
        return render_template('user.html',value=data,form=form)
    return render_template('user.html',form=form)

# shows available movies upcoming not relesed
@trail.route('/upcoming', methods=['GET', 'POST'])
def upcoming():
    cur = mysql.connection.cursor()
    result=cur.execute("SELECT * from movie where movieStatus='Upcoming'")
    #print(s)
    if result > 0:
        data = cur.fetchall()
        cur.close()
        return render_template('upcomingmovie.html', value=data)
    return render_template('upcomingmovie.html')

# shows available movie passed out
@trail.route('/past', methods=['GET', 'POST'])
def past():
    cur = mysql.connection.cursor()
    result=cur.execute("SELECT * FROM moviearchive WHERE moviearchive.movieId not in (SELECT movieId from movie where movieStatus='Released') and movieStatus='Released'")
    #print(s)
    if result > 0:
        data = cur.fetchall()
        cur.close()
        return render_template('pastmovie.html', value=data)
    return render_template('pastmovie.html')

# not needed
@trail.route('/user/<string:s>', methods=['GET', 'POST'])
def userSpe(s):
    cur = mysql.connection.cursor()
    #print(s)
    if result > 0:
        data = cur.fetchall()
        cur.close()
        return render_template('user.html',value=data)

    return render_template('user.html')

# Shows a chart of which movie is getting hits in theater
@trail.route('/userSuggestion', methods=['GET', 'POST'])
def userSuggestion():
    cur = mysql.connection.cursor()
    cur.callproc('userSuggestion')
    st=cur.fetchall()
    #print(st)
    cur.close()
    l = list(st[0]['name'].split("+"))
    l.pop()
    x=[0]*len(l)
    y=['f']*len(l)
    for i in range(0, len(l)):
        l[i] = list(l[i].split(":"))
        x[i]=int(l[i][1])
        y[i]=l[i][0]

    labels = y
    sizes = x
    ex=[0]*len(x)
    mx=min(x)
    index=0
   # print(mx)
    for i in range(len(x)):
        if mx==x[i]:
            index=i;
    ex[index]=0.1

   # print(y)
    #explode = (0, 0.1, 0, 0)  # only "explode" the 2nd slice (i.e. 'Hogs')
# explode=explode,

    fig1, ax1 = plt.subplots()
    ax1.pie(sizes,explode=ex, labels=labels, autopct='%1.1f%%',
            shadow=True, startangle=int(360/len(x)))
    ax1.axis('equal')  # Equal aspect ratio ensures that pie is drawn as a circle.

    plt.show()
    return redirect(url_for('user'))


# Shows detail of selected movie
@trail.route('/movieDeep/<int:movieId>/<int:theaterId>', methods=['GET', 'POST'])
def movieDeep(movieId,theaterId):
    cur = mysql.connection.cursor()
    cur.execute("DELETE FROM forslot WHERE  1")
    mysql.connection.commit()
    result = cur.execute("SELECT * from movie,timmingofmovie WHERE movieId=slotMovieId and slotTheaterId=%s and movieId=%s ", ([theaterId], [movieId]))
    if result > 0:
        data = cur.fetchall()
        cur.execute("select mccastName from moviecast where mcmovieId=%s",[movieId])
        d=cur.fetchall()
        cur.close()
        #print(d)
        return render_template('movieDetail.html', value=data,value2=d,len = len(data))
    return render_template('movieDetail.html')

# allow user to select his preferable seats.. also not allow if its already booked
@trail.route('/seatlook/<int:movieId>/<int:theaterId>/<int:screenId>/<string:slot>', methods=['GET', 'POST'])
def seatlook(movieId,theaterId,screenId,slot):
    cur = mysql.connection.cursor()
    #print(slot)

    cur.execute("INSERT INTO forslot VALUES ( %s , %s, %s, %s)", ([movieId], [theaterId], [screenId], [slot]))
    result = cur.execute("SELECT * FROM seat ORDER BY seatEprice DESC ")
    if result > 0:
        data1 = cur.fetchall()
        cur.execute("SELECT bseatId FROM seatbooked where (bmovieId=%s and btheaterId =%s and bscreenId = %s and bslot=%s and paymentStatus=1) ",([movieId], [theaterId], [screenId],slot))
        data2 = cur.fetchall()
        mysql.connection.commit()
        cur.close()
        strng = json.dumps(data2)
        print(len(data2))
        return render_template('seatlook.html', value1=data1,len=len(data2),value=strng,totalRow=len(data2), movieId=movieId,theaterId=theaterId,screenId=screenId,slot=slot )
    return render_template('seatlook.html')

# book selected seats with payment status 0 such that if he don't pay we can delete the data
@trail.route('/addInDb/<int:movieId>/<int:theaterId>/<int:screenId>/<string:seat>', methods=['GET', 'POST'])
def addInDb(movieId,theaterId,screenId,seat):

    l = list(seat.split(">"))
    for i in range(len(l)):
        l[i] = list(l[i].split("-"))
    #print(l)
    cur = mysql.connection.cursor()
    cur.execute("delete from seatbooked where paymentStatus=0")
    s=""
    for i in range(len(l)):
        if (l[i][0]=='0'):
            num=int(l[i][1])
            s='P'+str(num+1)
            cur.execute("select fsslot from forslot where fsmovieId=%s and fstheaterId=%s and fsscreenId=%s",([movieId],[theaterId],[screenId]))
            slot=cur.fetchone()
            #print(slot)
            cur.execute('INSERT INTO seatbooked (bmovieId,btheaterId,bscreenId,bseatId,bslot)VALUES (%s,%s,%s,%s,%s)',([movieId],[theaterId],[screenId],s,slot['fsslot']))
        elif(l[i][0]=='1'):
            num=int(l[i][1])
            s='G'+str(num+1)
            cur.execute("select fsslot from forslot where fsmovieId=%s and fstheaterId=%s and fsscreenId=%s",([movieId], [theaterId], [screenId]))
            slot = cur.fetchone()
            cur.execute('INSERT INTO seatbooked (bmovieId,btheaterId,bscreenId,bseatId,bslot)VALUES (%s,%s,%s,%s,%s)',([movieId], [theaterId], [screenId], s, slot['fsslot']))
        else:
            num=int(l[i][1])
            s='S'+str(num+1)
            cur.execute("select fsslot from forslot where fsmovieId=%s and fstheaterId=%s and fsscreenId=%s",([movieId], [theaterId], [screenId]))
            slot = cur.fetchone()
            # print(slot)
            cur.execute('INSERT INTO seatbooked (bmovieId,btheaterId,bscreenId,bseatId,bslot)VALUES (%s,%s,%s,%s,%s)',([movieId], [theaterId], [screenId], s, slot['fsslot']))

        mysql.connection.commit()
    cur.close()
    return redirect(url_for('userLogin',movieId=movieId,theaterId=theaterId,screenId=screenId))

# Now login or register user
class UserRegisterForm(Form):
    userName = StringField('userName', [validators.Length(min=2, max=30)])
    userPassword = PasswordField('userPassword', [validators.Length(min=8, max=15)])
    userFirstName = StringField('userFirstName', [validators.Length(min=2, max=30)])
    userLastName =StringField('userLastName',[validators.Length(min=2, max=30)])
    userEmail = StringField('userEmail', [validators.Length(min=12, max=30)])
    userBirthdate= DateField('userBithdate', format='%Y-%m-%d')
    userContact = DecimalField('userContact', places=0, rounding=None, use_locale=False, number_format=None)

# user do register and render to login page
@trail.route('/userRegister/<int:movieId>/<int:theaterId>/<int:screenId>', methods=['GET', 'POST'])
def userRegister(movieId,theaterId,screenId):
    form = UserRegisterForm(request.form)
    if request.method == 'POST' and form.validate():
        userName = form.userName.data
        userPassword = form.userPassword.data
        userFirstName = form.userFirstName.data
        userLastName= form.userLastName.data
        userEmail= form.userEmail.data
        userBirthdate  = form.userBirthdate.data
        userContact = form.userContact.data
        flag = 0
        error = ""
        try:
            cur = mysql.connection.cursor()
            cur.execute("INSERT INTO user VALUES (NULL, %s, %s, %s, %s, %s, %s, %s)",
                        ( userName, userPassword, userFirstName, userLastName, userEmail, userBirthdate, userContact))
            mysql.connection.commit()
            cur.close()
        except Exception as e:
            flag = 1
            error = e

        if flag == 1:
            return  render_template("usernameExcept.html",error=error,movieId=movieId,theaterId=theaterId,screenId=screenId)
        else:
            return redirect(url_for('userLogin',movieId=movieId,theaterId=theaterId,screenId=screenId))

    return render_template('userRegister.html', form=form,movieId=movieId,theaterId=theaterId,screenId=screenId)

# Allow user to login and render feedback page if user previously booked movie from this site
# else render to refreshment page
@trail.route('/userlogin/<int:movieId>/<int:theaterId>/<int:screenId>', methods=['GET', 'POST'])
def userLogin(movieId,theaterId,screenId):
    if request.method == 'POST':
        username = request.form['username']
        password_candidate = request.form['userPassword']
        cur = mysql.connection.cursor()
        result = cur.execute("SELECT * FROM user WHERE username = %s", [username])
        if result > 0:
            data = cur.fetchone()
            password = sha256_crypt.encrypt(data['userPassword'])
            if sha256_crypt.verify(password_candidate, password):
                # Passed
                session['logged_in'] = True
                session['username'] = username
                cur.execute("select userId from user where userName=%s", [username])
                id = cur.fetchone()
                cur.execute('SELECT movieRate(%s) ',[id['userId']])
                res=cur.fetchone()

                ind='movieRate({})'.format(id['userId'])
                mysql.connection.commit()
                #result=cur.execute("SELECT movie.movieId ,movie.movieName,movieRating FROM movie,usermovie WHERE  umUserId=%s and movie.movieId=umMovieId and umRating IS null",[id['userId']])
                #print(res)
                if res[ind]!='no':
                    l=list(res[ind].split(','))
                    mid=int(l[0])
                    mname=l[1]
                    mr=float(l[2])
                    return redirect(url_for('movieReview',movieId=movieId,theaterId=theaterId,screenId=screenId,mid=mid,mname=mname,username=username,uid=id['userId'],mr=mr))
                else:
                    return redirect(url_for('towardsCombo',movieId=movieId,theaterId=theaterId,screenId=screenId,username=username))
            else:
                error = 'Invalid login'
                return render_template('userlogin.html', error=error, movieId=movieId,theaterId=theaterId)
            # Close connection
            cur.close()
        else:
            error = 'Username not found'
            return render_template('userlogin.html', error=error, movieId=movieId,theaterId=theaterId,screenId=screenId)

    return render_template('userlogin.html',movieId=movieId,theaterId=theaterId,screenId=screenId)


# this is for movie feedback in case user has history with this site
class MovieReview(Form):
    review = TextAreaField('review', [validators.Length(min=10, max=200)])
    rate = DecimalField('rate', places=2, rounding=None)

@trail.route('/movieReview/<int:movieId>/<int:theaterId>/<int:screenId>/<int:mid>/<string:mname>/<string:username>/<int:uid>/<float:mr>', methods=['GET', 'POST'])
def movieReview(movieId,theaterId,screenId,mname,mid,username,uid,mr):
    form = MovieReview(request.form)
    if request.method == 'POST' and form.validate():
        review= form.review.data
        rate=form.rate.data
        #print(mr)
        cur = mysql.connection.cursor()
        cur.execute("UPDATE usermovie SET umReview=%s,umRating=%s WHERE umUserId=%s and umMovieId=%s",(review,rate, uid,mid))
        mr=(mr+float(rate))/2
        cur.execute("UPDATE movie SET movieRating=%s WHERE movieId=%s",(mr,mid))
        mysql.connection.commit()
        cur.close()

        return redirect(url_for('towardsCombo', movieId=movieId, theaterId=theaterId, screenId=screenId, username=username))

    return render_template('movieReview.html', form=form,mname=mname)


# Allow user to book combo from the theater in which movie seats are booked
@trail.route('/towardsCombo/<int:movieId>/<int:theaterId>/<int:screenId>/<string:username>', methods=['GET', 'POST'])
def towardsCombo(movieId,theaterId,screenId,username):
    cur = mysql.connection.cursor()
    cur.execute("SELECT userId from user where userName=%s", [username])
    userId = cur.fetchone()#userId['userId']
    cur.execute("UPDATE seatbooked SET buserId=%s WHERE bmovieId=%s and btheaterId=%s and bscreenId=%s and buserId IS NULL",(userId['userId'],[movieId],[theaterId],[screenId]))

    result = cur.execute("SELECT * FROM combo where comboTheaterId=%s",[theaterId])
    if result > 0:
        data = cur.fetchall()
        return render_template('towardsCombo.html',value=data, movieId=movieId, theaterId=theaterId, screenId=screenId,  username=username)
    return render_template('towardsCombo.html', movieId=movieId,theaterId=theaterId,screenId=screenId,username=username)

# Allow user to enter quantity
class comboquantity(Form):
    quantity = IntegerField('quantity')
    wantMore = StringField('wantMore', [validators.Length(min=2, max=3)])

@trail.route('/comboQuantity/<int:movieId>/<int:theaterId>/<int:screenId>/<string:username>/<int:comboId>',methods=['GET','POST'])
def comboQuantity(movieId,theaterId,screenId,username,comboId):
    form = comboquantity(request.form)
    cur = mysql.connection.cursor()
    cur.execute("SELECT combo.comboQuantity from combo where combo.comboId=%s and combo.comboTheaterId=%s",([comboId],[theaterId]))
    q=cur.fetchone()
    qu=int(q['comboQuantity'])
    #print(qu)
    if request.method == 'POST' and form.validate():
        quantity = form.quantity.data
        wantMore = form.wantMore.data
        cur.execute("SELECT comboPrice from combo where comboId=%s and comboTheaterId=%s",([comboId],[theaterId]))
        price=cur.fetchone()
        #print(price)
        tprice=int(price['comboPrice'])*quantity
        cur.execute("SELECT userId from user where userName=%s", [username])
        userId=cur.fetchone()

        cur.execute("INSERT INTO usercombobridge VALUES ( %s, %s, %s, %s, %s,0)",(userId['userId'],[comboId],[theaterId],quantity,tprice))
        mysql.connection.commit()
        cur.close()

        if wantMore == 'YES' or wantMore=='yes':
            return redirect(url_for('towardsCombo', movieId=movieId, theaterId=theaterId, screenId=screenId, username=username))
        else:
            return redirect(url_for('ticket',movieId=movieId, theaterId=theaterId, screenId=screenId,  username=username))
   # return render_template('comboQuantity.html',movieId=movieId,theaterId=theaterId,screenId=screenId,slot=slot,seatId=seatId,username=username,comboId=comboId, form=form)
    return render_template('comboQuantity.html',movieId=movieId, theaterId=theaterId, screenId=screenId, username=username, quantity=qu,form=form)

# show user his tickett with total bill
@trail.route('/ticket/<int:movieId>/<int:theaterId>/<int:screenId>/<string:username>', methods=['GET', 'POST'])
def ticket(movieId,theaterId,screenId,username):
    cur = mysql.connection.cursor()
    cur.callproc('showTicket',(movieId,theaterId,screenId,username))
    st = cur.fetchone()

    l=list(st['name'].split('+'))

    dat=str(dt.datetime.today() + dt.timedelta(days=1))
    d=list(dat.split(' '))
    dat=d[0]


    l[6]=list(l[6].split(','))
    l[6].pop()
    totalSeat=len(l[6])
    l[7]=list(l[7].split(';'))
    l[7].pop()
    for i in range(len(l[7])):
        l[7][i]=list(l[7][i].split(','))
    if l[4]=='time1':
        slot='9:30'
    elif l[4]=='time2':
        slot='12:30'
    else:
        slot='8:00'
    price=l[5]
    cur.close()
    print(l)
    length=len(l[7])
    if(length>0):
        return render_template('ticket.html', l=l,dat=dat,slot=slot,len=length,totalSeat=totalSeat,movieId=movieId, theaterId=theaterId, screenId=screenId, username=username,price=price)
    return render_template('ticketComboless.html',l=l,dat=dat,slot=slot,len=length,totalSeat=totalSeat,movieId=movieId, theaterId=theaterId, screenId=screenId, username=username,price=price)

# show user his account
@trail.route('/account/<string:username>/<int:payment>/<int:movieId>/<int:theaterId>/<int:screenId>', methods=['GET', 'POST'])
def account(username,payment,movieId, theaterId, screenId):
    cur = mysql.connection.cursor()
    result = cur.execute("SELECT * from userAccount,user where userName = %s and useraccount.accountUserId=user.userId ", [username])
    if result > 0:
        data = cur.fetchall()
        cur.close()
        return render_template('account.html', value=data, len=len(data), username=username ,payment=payment,movieId=movieId,theaterId= theaterId,screenId= screenId)
    return render_template('account.html')

# allow user to confirm his/her payment if enuff balance is present
@trail.route('/pdf/<int:accountId>/<int:price>/<int:movieId>/<int:theaterId>/<int:screenId>/<string:username>', methods=['GET', 'POST'])
def pdf(accountId,price,movieId, theaterId, screenId, username):
    flag=0
    cur = mysql.connection.cursor()
    cur.execute("SELECT userId from user where userName=%s", [username])
    userId = cur.fetchone()
    error=''
    try:
        cur.callproc('tableUpdate', (accountId,price,userId['userId'],movieId, theaterId, screenId))
        st = cur.fetchone()
        #cur.execute("UPDATE useraccount SET `accountBalance`=-10 WHERE useraccount.accountUserId=%s",[userId['userId']])
        mysql.connection.commit()
        cur.close()
        #return render_template('dash.html')
    except Exception as e:
        print(e)
        error=e
        flag=1

    #print(flag)
    if(flag==1):
        return render_template('lowBalance.html',error=error)
    return redirect(url_for('user'))
        #return redirect(url_for('pdf',accountId=accountId,price=price,movieId=movieId, theaterId=theaterId, screenId=screenId,username=username))

"""
@trail.route('/employee', methods=['GET', 'POST'])
def employee():
    return render_template('employee.html')


"""
#Finish the tour of website
@trail.route('/thanks')
def thank():
    return render_template('temp.html')

# Main module
if __name__ == '__main__':

    trail.secret_key = 'secret123'
    trail.run(debug=True)