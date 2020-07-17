from flask import Flask, render_template

Airport = Flask(__name__)


@Airport.route('/')
def index():
    return render_template('homeAgain.html')

if __name__ == '__main__':
    Airport.run(debug=True)