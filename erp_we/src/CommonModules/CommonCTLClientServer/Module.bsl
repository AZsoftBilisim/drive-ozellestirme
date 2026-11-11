
#Region Internal

// Gets the header value regardless of case.
//
// Parameters: 
//  RequestResponse - HTTPRequest, HTTPResponse, HTTPServiceRequest, HTTPServiceResponse - request or response.
//  Title - String - title name.
//
// Returns:
//  String, Undefined - the value of the header.
//
Function HTTPHeader(RequestResponse, Val Title) Export
	
	Title = Lower(Title);
	For Each KeyAndValue In RequestResponse.Headers Do
		If Lower(KeyAndValue.Key) = Title Then
			Return KeyAndValue.Value;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

#EndRegion
