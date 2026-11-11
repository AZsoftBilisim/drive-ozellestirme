////////////////////////////////////////////////////////////////////////////////
// THE MODULE CONTAINS PROCEDURES AND FUNCTIONS FOR REGISTERING EXCHANGE OBJECTS WITH THE MOBILE APPLICATION "1C:ORDERS"
// - registration of objects in exchange nodes
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Handler for subscribing to the" before Recording " event in the directory.
//
// Parameters:
//  Source - CatalogObject - event source;
//  Cancel - Boolean - refusal to perform.
//
Procedure RegisterCatalogChangesBeforeRecordingForSharingWithMobileApp (Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Not GetFunctionalOption("UseMobileApplication1COrders") Then
		Return;
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	If Source.IsFolder Then
		Return;
	EndIf;
	
	RegisterImageOfProductItem = False;
	If ValueIsFilled(Source.PicturesFile) Then
		If Source.IsNew() Then
			RegisterImageOfProductItem = True;
		Else
			OldImageFile = Common.ObjectAttributeValue(Source.Ref, "PicturesFile");
			If Not Source.PicturesFile = OldImageFile Then
				RegisterImageOfProductItem = True;
			EndIf;
		EndIf;
	EndIf;
	If RegisterImageOfProductItem Then
		RecordChanges(Source.PicturesFile, False);
	EndIf;
EndProcedure

// Handler for subscribing to the directory's "Record" event.
//
// Parameters:
//  Source - CatalogObject - event source;
//  Cancel - Boolean - refusal to perform.
//
Procedure RegisterChangesWhenWritingCatalogForExchangeWithCustomerOrders(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Not GetFunctionalOption("UseMobileApplication1COrders") Then
		Return;
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	RecordChanges(Source);
EndProcedure

// Handler for subscribing to the "task Record" event.
//
// Parameters:
//  Source - DocumentObject.SalesOrder, DocumentObject.JobForSalesRepresentative - event source;
//  Cancel - Boolean - refusal to perform.
//
Procedure RegisterChangesWhenWritingJobToExchangeWithCustomerOrders(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Not GetFunctionalOption("UseMobileApplication1COrders") Then
		Return;
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	NotRegisterChanges = False;
	If Source.AdditionalProperties.Property("NotRegisterChanges", NotRegisterChanges) Then
		If NotRegisterChanges Then
			Return;
		EndIf;
	EndIf;
	
	NodesForRegistration = New Array;
	JobForSalesRepresentative = "";
	
	SetPrivilegedMode(True);
	
	If TypeOf(Source) = Type("DocumentObject.SalesOrder") Then
		
		If TypeOf(Source.DocumentBasis) = Type("DocumentRef.JobForSalesRepresentative")
			And ValueIsFilled(Source.DocumentBasis) Then
			
			Try
				JobForSalesRepresentative = Source.DocumentBasis.GetObject();
			Except
				Raise NStr("vi = 'Không tìm thấy tham chiếu đến chứng từ cơ sở.';
							|ru = 'Не найдена ссылка на документ основание.';
							|en = 'No reference found to base document.'; fa = 'No reference found to base document.';
							|it = 'Non è stato trovato il link al domcumento di base.';
							|pl = 'Nie znaleziono odnośnika do dokumentu podstawy.';
							|tr = 'Temel belgeye ilişkin bir referans bulunamadı.'",
				CommonClientServer.DefaultLanguageCode());
			EndTry;
			
			NodesForRegistration = NodesForRegisteringTasks(JobForSalesRepresentative.SalesRepresentative);
		EndIf;
		
	ElsIf TypeOf(Source) = Type("DocumentObject.JobForSalesRepresentative") Then
		
		If Source.Status = Enums.SalesRepresentativeTaskStatuses.ToProcessing Then
			
			JobForSalesRepresentative = Source;
			NodesForRegistration = NodesForRegisteringTasks(Source.SalesRepresentative);
		EndIf;
	EndIf;
	
	If NodesForRegistration.Count()>0 Then
		ExchangePlans.RecordChanges(NodesForRegistration, JobForSalesRepresentative);
	EndIf;
	
	SetPrivilegedMode(False);
EndProcedure

// Handler subscribe to event "Parazitirovanii".
//
// Parameters:
//  Source - InformationRegisterRecordSet.ItemsPrices - event source;
//  Cancel - Boolean - refusal to perform;
//  Replacing - Boolean - indicates whether register entries are being replaced.
//
Procedure RegisterInformationRegisterChangesForSharingWithMobileAppCustomerOrdersBeforeRecording(Source, Cancel, Replacing) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Not GetFunctionalOption("UseMobileApplication1COrders") Then
		Return;
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	RecordChanges(Source);
EndProcedure

#EndRegion

#Region Private

Procedure RecordChanges(Object, IsObject = True)
	
	SetPrivilegedMode(True);
	
	Exceptions = New Array;
	Exceptions.Add(ExchangePlans.MobileApplicationSalesOrders.ThisNode());
	
	If IsObject And Object.DataExchange.Load Then
		Exceptions.Add(Object.DataExchange.Sender);
	EndIf;
	
	NodesForRegistration = NodesForRegistration(Exceptions);
	
	MobileApplicationSalesOrdersOverridable.RegisterChangesForExchangeNodes(NodesForRegistration, Object);
EndProcedure

// Returns an array of exchange plan nodes, including excluded ones.
//
// Parameters:
//  Exceptions - Array - array of nodes that do not need to be registered for changes.
//
// Returns:
//  Array - array of nodes for registering changes.
//
Function NodesForRegistration(Exceptions)
	
	SetPrivilegedMode(True);
	
	Query = New Query("SELECT
	|	MobileApplicationSalesOrders.Ref
	|FROM
	|	ExchangePlan.MobileApplicationSalesOrders AS MobileApplicationSalesOrders
	|WHERE
	|	NOT MobileApplicationSalesOrders.DeletionMark
	|	AND NOT MobileApplicationSalesOrders.Ref IN (&ExceptionsArray)");
	
	Query.SetParameter("ExceptionsArray", Exceptions);
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
EndFunction

// Returns an array of exchange plan nodes by sales representative.
//
// Parameters:
//  SalesRepresentative - CatalogRef.Users - the sales representative to find the nodes for.
//
// Returns:
//  Array - array of nodes for registering changes.
//
Function NodesForRegisteringTasks(SalesRepresentative)
	
	SetPrivilegedMode(True);
	
	Query = New Query("SELECT
	|	MobileApplicationSalesOrders.Ref
	|FROM
	|	ExchangePlan.MobileApplicationSalesOrders AS MobileApplicationSalesOrders
	|WHERE
	|	NOT MobileApplicationSalesOrders.DeletionMark
	|	AND MobileApplicationSalesOrders.User = &SalesRepresentative");
	
	Query.SetParameter("SalesRepresentative", SalesRepresentative);
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
EndFunction

#EndRegion
