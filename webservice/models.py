import peewee as pw

#myDB = pw.MySQLDatabase("mydb", host="epicrunner.dk.panditest.dk", port=3306, user="t8_epicrunner", passwd="rPqfK@4L")
myDB = pw.MySQLDatabase("mydb", host="127.0.0.1", port=3306, user="root", passwd="password")

class MySQLModel(pw.Model):
    """A base model that will use our MySQL database"""
    class Meta:
        database = myDB


class actions(MySQLModel):
    userid    = pw.IntegerField()
    ip 	      = pw.TextField()
    timestamp = pw.IntegerField()
    action    = pw.TextField()

test = "hej med test"
print test
# We are ready, CONNECT
myDB.connect()