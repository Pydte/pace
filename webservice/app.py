#gunicorn app:wsgi
import falcon
import json
import models

class ActionsResource(object):
    def on_get(self, req, resp):
        """Handles GET requests"""
        resp.status = falcon.HTTP_200
        query = actions.select().where(actions.userid == 10)
		for pet in query:
	     	print pet.id, pet.ip

        resp.body = 'Hello world!'
 
    def on_post(self, req, resp):
        """Handles POST requests"""
        try:
            raw_json = req.stream.read()
        except Exception as ex:
            raise falcon.HTTPError(falcon.HTTP_400,
                'Error',
                ex.message)
 
        try:
            result_json = json.loads(raw_json, encoding='utf-8')
        except ValueError:
            raise falcon.HTTPError(falcon.HTTP_400,
                'Malformed JSON',
                'Could not decode the request body. The '
                'JSON was incorrect.')
 
        resp.status = falcon.HTTP_202
        resp.body = json.dumps(result_json, encoding='utf-8')
 


# falcon.API instances are callable WSGI apps
wsgi = api = falcon.API()
 
# Resources are represented by long-lived class instances
actions = ActionsResource()
 
# things will handle all requests to the '/things' URL path
api.add_route('/actions', things)