#Region Public

#EndRegion

#Region Private


// Blocking month-end closing by update handlers.
// 
// Returns:
//  Map of KeyAndValue:
//	 * Key - String - Update Handler Procedure
//	 * Value - Boolean - the sign of blocking the month-end closing
Function BlockingMonthEndClosingByUpdateHandlers() Export
	
	UpdateHandlers = New Map;
	
	// Do not affect the month-end closing
	Handlers = MonthEndTransactionsServer.UpdateHandlersThatDoNotAffectMonthEndClosing();
	For LineNumber = 1 To StrLineCount(Handlers) Do
		
		HandlerName = StrGetLine(Handlers, LineNumber);
		HandlerName = TrimAll(StrReplace(HandlerName, ",", ""));
		
		If IsBlankString(HandlerName) Then
			Continue;
		EndIf;
		
		UpdateHandlers.Insert(Lower(HandlerName), False);
		
	EndDo;
		
	// Blocking month-end closing
	Handlers = MonthEndTransactionsServer.UpdateHandlersBlockingMonthEndClosing();
	For LineNumber = 1 To StrLineCount(Handlers) Do
		
		HandlerName = StrGetLine(Handlers, LineNumber);
		HandlerName = TrimAll(StrReplace(HandlerName, ",", ""));
		
		If IsBlankString(HandlerName) Then
			Continue;
		EndIf;
		
		UpdateHandlers.Insert(Lower(HandlerName), True);
		
	EndDo;
		
	Return UpdateHandlers;
	
EndFunction

#EndRegion
