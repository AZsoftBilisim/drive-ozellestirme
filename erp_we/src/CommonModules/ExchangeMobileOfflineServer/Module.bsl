#If MobileStandaloneServer Then
#Region Public

// The service function for the initial initialization of the database, checks that data synchronization has not been previously performed
// Returns:
//	Structure - a collection that contains the following properties:
//		* ExchangeNodeCode - String - node code .
//
Function DataToCheck() Export
	
	Node = ExchangePlans.Mobile.ThisNode();
	NodeCode = Node["Code"];
	
	ReturnStructure = New Structure();
	ReturnStructure.Insert("ExchangeNodeCode", NodeCode);
	Return ReturnStructure;
	
EndFunction

// Service function for getting a constant
// Returns:
//	Structure - a collection that contains the following properties:
//		* Accepted - Number - Accepted records .
//		* Sent - Number - Sent recordings .
//
Function NewEntriesAcceptedSent() Export
	
	ReturnStructure = New Structure();
	ReturnStructure.Insert("Accepted", Constants.RegisterRecordsReceived.Get());
	ReturnStructure.Insert("Sent", Constants.RegisterRecordsSent.Get());
	Return ReturnStructure;
	
EndFunction

// The procedure synchronizes data with the main database. through a web service published by her
Procedure ExecuteDataExchange() Export
	
	NodeDescription = "Standalone node";
	
	CentralExchangeHub = ExchangePlans.Mobile.FindByCode("001");
	If CentralExchangeHub.IsEmpty() Then
		
		NewNode = ExchangePlans.Mobile.CreateNode();
		NewNode.Code = "001";
		NewNode.Description = NStr("vi = 'Trung tâm';
									|ru = 'Центральный';
									|en = 'Central'; fa = 'Central';
									|it = 'Centrale';
									|pl = 'Centralny';
									|tr = 'Merkezi'");
		NewNode.Write();
		CentralExchangeHub = NewNode.Ref;
		
	EndIf;
	
	Node = ExchangePlans.Mobile.ThisNode();
	NodeCode = Node["Code"];
	
	// Initialize the exchange, check if there is a necessary node in the exchange plan.
	NewCode = MainServer.ExchangeMobilePCCall.StartExchange(NodeCode,
		NodeDescription,
		CentralExchangeHub["ReceivedNo"],
		CentralExchangeHub["SentNo"]);
	
	If NodeCode <> NewCode Then
		
		NodeObject = Node.GetObject();
		NodeObject.Code = NewCode;
		NodeObject.Description = NodeDescription;
		NodeObject.Write();
		
	EndIf;
	
	SetPrivilegedMode(True);
	Constants.RegisterRecordsSent.Set(0);
	Constants.RegisterRecordsReceived.Set(0);
	SetPrivilegedMode(False);
	
	ExchangeData = ExchangeMobileGeneral.GenerateExchangeBatch(CentralExchangeHub);
	ExchangeData = MainServer.ExchangeMobilePCCall.ExecuteDataExchange(NodeCode, ExchangeData);
	ExchangeMobileGeneral.ReceiveExchangeBatch(CentralExchangeHub, ExchangeData);
	
EndProcedure

// Background task completion check function
// The function analyzes the status of the background task and information
// about errors that have occurred
//
// Parameters:
//  Id - UUID - id of the background task
//  ErrorText - String - parameter for returning error information
//
// Returns:
//  Boolean - True if the task is completed
//
Function DataExchangeIsOver(Id, ErrorText) Export
	
	ErrorText = "";
	
	If TypeOf(Id) <> Type("UUID") Then
		Return True;
	EndIf;

	Job = BackgroundJobs.FindByUUID(Id);
	If Job = Undefined Then
		Return True; // probably already pushed out of memory
	EndIf;
	
	If Job.State = BackgroundJobState.Active Then
		Return False;
	EndIf;
	
	If Job.State = BackgroundJobState.Failed Then
		ErrorText = Job.ErrorInfo.Description;
	EndIf;
	
	Return True;
	
EndFunction

// The function starts a background task for data synchronization
// Returns:
//  UUID
//
Function PerformDataExchangeInBackground() Export
	
	Job = BackgroundJobs.Execute("ExchangeMobileOfflineServer.ExecuteDataExchange",,, "Synchronization");
	Return Job.UUID;
	
EndFunction

// The function receives the node code of the exchange plan Mobile offline configuration for the current session
// Returns:
//  String - Exchange Plan Node code
//
Function CurrentNode() Export
	
	Return ExchangePlans.Mobile.ThisNode()["Code"];
	
EndFunction

// The procedure creates a Mobile Exchange plan node for offline configuration 
Procedure CreateExchangeNode() Export
	
	NodeDescription = "Standalone node";
	
	CentralExchangeHub = ExchangePlans.Mobile.FindByCode("001");
	If CentralExchangeHub.IsEmpty() Then
		
		NewNode = ExchangePlans.Mobile.CreateNode();
		NewNode.Code = "001";
		NewNode.Description = NStr("vi = 'Trung tâm';
									|ru = 'Центральный';
									|en = 'Central'; fa = 'Central';
									|it = 'Centrale';
									|pl = 'Centralny';
									|tr = 'Merkezi'");
		NewNode.Write();
		CentralExchangeHub = NewNode.Ref;
		
	EndIf;
	
	Node = ExchangePlans.Mobile.ThisNode();
	NodeCode = Node["Code"];
	
	NewCode = MainServer.ExchangeMobilePCCall.CreateExchangeNode(NodeCode, NodeDescription);
	
	If NodeCode <> NewCode Then
		
		NodeObject = Node.GetObject();
		NodeObject.Code = NewCode;
		NodeObject.Description = NodeDescription;
		NodeObject.Write();
		
	EndIf;
	
EndProcedure

// The function starts a background job to create a sharing plan node.
// Returns:
//  UUID
//
Function CreateExchangeNodeInBackground() Export
	
	Job = BackgroundJobs.Execute("ExchangeMobileOfflineServer.CreateExchangeNode");
	Return Job.UUID;
	
EndFunction

#EndRegion
#EndIf
