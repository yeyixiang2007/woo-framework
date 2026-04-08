class_name WooCancellationSource
extends RefCounted

var token: WooCancellationToken = WooCancellationToken.new()


func cancel(reason := "") -> bool:
	return token._cancel(reason)
