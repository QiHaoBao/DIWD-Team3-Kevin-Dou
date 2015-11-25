#!/usr/bin/env python

class Module:

	vt_id = -1
	package = ''

	def __init__(self, id, type, x, y, value):
		self.id = id
		self.type = type
		self.x = x
		self.y = y
		self.value = value

class IntegerModule(Module):

	def __init__(self, id, type, x, y, value=None):
		Module.__init__(id, type, x, y, value)


class MultiInputModule(Module):
	value = []
	def __init__(self, id, type, x, y, value):
		Module.__init__(id, type, x, y)
		self.value.append(value)

	def add(value):
		self.value.append(value)


