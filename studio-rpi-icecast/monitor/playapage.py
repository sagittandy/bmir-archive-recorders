"""
This class sends a message to the Burning Man ESD PlayaPage system.
	https://paging.burningman.org/playapage/
	
This class can also fetch a list of people who have pagers.


Prereqs:  You must have an account at PlayaPage.
	
Sample usage:
	import playapage
		
	username = 'xxxx'     # Sender's account username
	password = 'yyyy'     # Sender's account password
	person = '9999'       # Receiver person's ID number
	message = 'zzzz'      # Message body

	pp = playapage.PlayaPage(username, password)
	try:
		rsp = pp.list_people_uAPI()
		print(rsp)
		
		rsp = pp.send_uAPI(person, message)
		print(rsp)
		
		#pp.send_web(person, message)

	except Exception as e:	
		print(e)
		
AD 2022-0731-1154 Created
"""
import requests
import sys
import time


class PlayaPage:
 
	# Class constants.
	base_url = 'https://paging.burningman.org/playapage/'
	uapi_url = base_url + 'uAPI.php'
	login_url = base_url + 'index.php'
	send_url = base_url + 'page_send.php'
	logout_url = base_url + 'index.php?logout'
	session = requests.Session()


	# Constructor.
	def __init__(self, username, password):

		# Ensure both parameters are strings.
		if str != type(username) or str != type(password):
			raise Exception('Invocation error: username and password must be strings.')

		# Save.
		self.username = username
		self.password = password


	# Gets a list of people to whom pager messages may be sent.
	def get_people_uAPI(self):
		
		payload = { 
			'username': self.username, 
			'password': self.password, 
			'listpeople': ''
		}
		response = self.session.post(self.uapi_url, json=payload, timeout=7)
		if 200 != response.status_code:
			raise Exception('Error getting list of people. status_code=' % (response.status_code))
		rj = response.json()
		if 'status' in rj and 'ok' == rj['status'] and 'code' in rj and 200 == rj['code'] and 'people' in rj:
			print('Got list of people.')	
			return(rj)
		else:	
			raise Exception('Error: Could not get list of people. %s' % (repr(rj['messages'])))


	# Send a message to specified person using the Universal API.
	# The Universal API submits all parameters in one POST and does not
	# require a separate POSTs to login and logout.
	def send_uAPI(self, person, message):

		# Ensure both parameters are strings.
		if str != type(person) or str != type(message):
			raise Exception('Invocation error: person and message must be strings.')

		# Ensure the person string contains a whole number.
		try:
			int(person)
		except:
			raise Exception('Invocation error: person is not an integer number.')
		
		# Send message to pager.
		payload = { 
			'username': self.username, 
			'password': self.password, 
			'sendpage': {
				'recipients': {
					'people': [person],
					'groups': []
				},
				'message': message
			}
		}
		response = self.session.post(self.uapi_url, json=payload, timeout=7)
		if 200 != response.status_code:
			raise Exception('Error sending message to pager. status_code=' % (response.status_code))
		rj = response.json()
		if 'status' in rj and 'success' == rj['status'] and 'code' in rj and 200 == rj['code'] and 'messages' in rj and 'Page Sent' in rj['messages']:
			print('Success. Sent message.')
			return(rj)

		else:
			raise Exception('Error: Could not send message. %s' % (repr(rj['messages'])))
		

	# Login and send message to specified pager.
	# This function uses the same interface as a browser visiting the website.
	# Note: This method may be redundant with send_uAPI() and/or deprecated.
	def send_web(self, person, message):

		# Ensure both parameters are strings.
		if str != type(person) or str != type(message):
			raise Exception('Invocation error: person and message must be strings.')

		# Ensure the person string contains a whole number.
		try:
			int(person)
		except:
			raise Exception('Invocation error: person is not an integer number.')
				
		# Login.
		payload = { 
			'username': self.username, 
			'password': self.password 
		}
		response = self.session.post(self.login_url, data=payload, timeout=3)
		if 200 != response.status_code:
			raise Exception('Error logging in to playapage. status_code=' % (response.status_code))
		if 'Incorrect username or password' in response.text:
			raise Exception('Login error: Incorrect username or password.')
		if 'Welcome to PlayaPage' not in response.text:
			raise Exception('Login error: Could not log in.')  
		print('Logged in.')
		time.sleep(1)

		# Send message to pager.
		payload = { 
			'people': ':%s;' % person, 
			'groups': '', 
			'message': message, 
			'Send': 'Send' }
		response = self.session.post(self.send_url, data=payload, timeout=7)
		if 200 != response.status_code:
			raise Exception('Error sending message to pager. status_code=' % (response.status_code))
		if 'Your message has been queued' not in response.text:
			raise Exception('Error: Could not send message.')
		print('Sent message.')
		time.sleep(1)

		# Logout.
		response = self.session.post(self.logout_url, timeout=3)
		if 200 != response.status_code:
			raise Exception('Error logging out from playapage. status_code=' % (response.status_code))
		if 'logintitle' not in response.text:
			raise Exception('Error: Did not log out successfully.')
		print('Logged out.')
		
		

