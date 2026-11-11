#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds a link between the IP object and the UP object.
//
// Parameters:
//   ID - String - the ID of the object BEFORE.
//   Type - String - the object type is UP TO.
//   ObjectIS - AnyRef - the IP object.
//   WhetherFilesAreAttached - Boolean - True if there are attached files in the DO.
//   AdditionalData - Arbitrary - additional data that you want to save to the repository.
//
Procedure AddLink(ID, Type, ObjectIS, WhetherFilesAreAttached = Undefined,
		AdditionalData = Undefined) Export
	
	If Not ValueIsFilled(ObjectIS) Then
		Raise StrTemplate(
			NStr("vi = 'Đặt liên kết đối tượng DM (%1, %2) với đối tượng không tồn tại của hệ thống được tích hợp.';
				|ru = 'Установка связи объекта ДО (%1, %2) с несуществующим объектом ИС.';
				|en = 'Link the Document Management object (%1, %2) with a non-existing information system object.'; fa = 'Link the Document Management object (%1, %2) with a non-existing information system object.';
				|it = 'Установка связи объекта ДО (%1, %2) с несуществующим объектом ИС.';
				|pl = 'Link the Document Management object (%1, %2) with a non-existing information system object.';
				|tr = 'İş Akışı nesnesi ile Entegre Sisteminin var olmayan nesnesi arasında bağlantı kurma (%1, %2).'"), ID, Type);
	EndIf;
	
	If RecordIsAlreadyThere(ID, Type, ObjectIS) Then
		Return;
	EndIf;
	
	RecordSet = CreateRecordSet();
	
	RecordSet.Filter.Object.Set(ObjectIS);
	RecordSet.Clear();
	
	Record = RecordSet.Add();
	
	Record.Object = ObjectIS;
	Record.ObjectTypeDM = Type;
	Record.ObjectIDDM = ID;
	If AdditionalData <> Undefined Then
		Record.AdditionalData = New ValueStorage(AdditionalData, New Deflation(9));
	EndIf;
	
	RecordSet.Write();
	
	IntegrationWith1CDocumentManagementCore.OnAdd1CDocumentManagementAttachedFiles(
		ID,
		Type,
		ObjectIS,
		WhetherFilesAreAttached);
	
EndProcedure

// Removes the link between the IP object and the UP object.
//
// Parameters:
//   ID - String - the ID of the object BEFORE.
//   Type - String - the object type is UP TO.
//   ObjectIS - AnyRef - the IP object.
//
Procedure DeleteLink(ID, Type, ObjectIS) Export
	
	BeginTransaction();
	
	Try
		
		DataLock = New DataLock;
		DataLockItem = DataLock.Add("InformationRegister.ObjectsIntegratedWith1CDocumentManagement");
		DataLockItem.SetValue("Object", ObjectIS);
		DataLockItem.SetValue("ObjectIDDM", ID);
		DataLockItem.Mode = DataLockMode.Exclusive;
		DataLock.Lock();
		
		TypesArray = CommonClientServer.ValueInArray(Type);
		If Type = "DMDocument" Then
			TypesArray.Add("DMInternalDocument");
			TypesArray.Add("DMIncomingDocument");
			TypesArray.Add("DMOutgoingDocument");
		EndIf;
		If Type = "DMInternalDocument" Then
			TypesArray.Add("DMDocument");
		EndIf;
		If Type = "DMIncomingDocument" Then
			TypesArray.Add("DMDocument");
		EndIf;
		If Type = "DMOutgoingDocument" Then
			TypesArray.Add("DMDocument");
		EndIf;
		
		Query = New Query(
			"SELECT
			|	ObjectsIntegratedWith1CDocumentManagement.Object AS Object,
			|	ObjectsIntegratedWith1CDocumentManagement.ObjectTypeDM AS ObjectTypeDM,
			|	ObjectsIntegratedWith1CDocumentManagement.ObjectIDDM AS ObjectIDDM
			|FROM
			|	InformationRegister.ObjectsIntegratedWith1CDocumentManagement AS ObjectsIntegratedWith1CDocumentManagement
			|WHERE
			|	ObjectsIntegratedWith1CDocumentManagement.Object = &ObjectIS
			|	AND ObjectsIntegratedWith1CDocumentManagement.ObjectIDDM = &ID
			|	AND ObjectsIntegratedWith1CDocumentManagement.ObjectTypeDM IN (&TypesArray)");
		Query.SetParameter("ObjectIS", ObjectIS);
		Query.SetParameter("ID", ID);
		Query.SetParameter("TypesArray", TypesArray);
		QueryResult = Query.Execute();
		
		If QueryResult.IsEmpty() Then
			RollbackTransaction();
			Return;
		EndIf;
		
		Selection = QueryResult.Select();
		While Selection.Next() Do
			Record = CreateRecordManager();
			Record.Object = Selection.Object;
			Record.ObjectTypeDM = Selection.ObjectTypeDM;
			Record.ObjectIDDM = Selection.ObjectIDDM;
			Record.Delete();
		EndDo;
		
		IntegrationWith1CDocumentManagementCore.OnRemove1CDocumentManagementAttachedFiles(
			ID,
			Type,
			ObjectIS);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

// Gets the associated IP object by the object UP TO.
//
// Parameters:
//   ID - String - the ID of the object BEFORE.
//   Type - String - the object type is UP TO.
//   ObjectType - String - optional, IP object type.
//
// Returns:
//   Undefined - if there is no connection.
//   Documentlink
//   Referenceslink
//   The plan of the kind of calculation is a link
//   Type characteristicslink - a link to an IP object.
//
Function ReferenceToIPObjectAccordingToDocumentManagementData(ID, Type, ObjectType = Undefined) Export
	
	Query = New Query(
		"SELECT TOP 1
		|	ObjectsIntegratedWith1CDocumentManagement.Object
		|FROM
		|	InformationRegister.ObjectsIntegratedWith1CDocumentManagement AS ObjectsIntegratedWith1CDocumentManagement
		|WHERE
		|	ObjectsIntegratedWith1CDocumentManagement.ObjectTypeDM = &ObjectTypeDM
		|	AND ObjectsIntegratedWith1CDocumentManagement.ObjectIDDM = &ObjectIDDM
		|	AND &Condition");
	Query.SetParameter("ObjectTypeDM", Type);
	Query.SetParameter("ObjectIDDM", ID);
	
	If ObjectType = Undefined Then
		Query.Text = StrReplace(Query.Text, "&Condition", "TRUE");
	Else
		Query.Text = StrReplace(Query.Text,
			"&Condition",
			"VALUETYPE(ObjectsIntegratedWith1CDocumentManagement.Object) = &ObjectType");
		Query.SetParameter("ObjectType", ObjectType);
	EndIf;
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return Undefined;
		
	Else
		Selection = Result.Select();
		Selection.Next();
		
		Return Selection.Object;
	EndIf;
	
EndFunction

// receives 1C object data from the register:The workflow associated with the configuration object-the consumer.
//
// Parameters:
//   ReferenceToExternalObject - AnyRef - a reference to the consumer configuration object.
//
// Returns:
//   Undefined, Structure - object data:
//     * name - String - name of the Workflow object.
//     * ID - String - the unique identifier of the object in the Document Flow.
//     * type - String - the name of the XDTO type corresponding to the object BEFORE.
//     * ExternalObject - AnyRef - a link to the associated IP object.
//     * AdditionalData - Arbitrary - additional data.
//
Function ObjectDataUpToExternalObject(ReferenceToExternalObject) Export
	
	If ReferenceToExternalObject = Undefined Then
		Return Undefined;
	EndIf;
	
	Query = New Query(
		"SELECT
		|	ObjectsIntegratedWith1CDocumentManagement.ObjectTypeDM AS ObjectTypeDM,
		|	ObjectsIntegratedWith1CDocumentManagement.ObjectIDDM AS ObjectIDDM,
		|	ObjectsIntegratedWith1CDocumentManagement.AdditionalData AS AdditionalData
		|FROM
		|	InformationRegister.ObjectsIntegratedWith1CDocumentManagement AS ObjectsIntegratedWith1CDocumentManagement
		|WHERE
		|	ObjectsIntegratedWith1CDocumentManagement.Object = &ExternalObject");
	Query.SetParameter("ExternalObject", ReferenceToExternalObject);
	
	Selection = Query.Execute().Select();
	LinkCount = Selection.Count();
	
	If LinkCount = 1 Then
		Selection.Next();
		Result = New Structure;
		Result.Insert("name", TrimAll(ReferenceToExternalObject));
		Result.Insert("ID", Selection.ObjectIDDM);
		Result.Insert("type", Selection.ObjectTypeDM);
		Result.Insert("ExternalObject", ReferenceToExternalObject);
		Result.Insert("AdditionalData", Undefined);
		If TypeOf(Selection.AdditionalData) = Type("ValueStorage") Then
			Result.AdditionalData = Selection.AdditionalData.Get();
		EndIf;
		Return Result;
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region Private

Function RecordIsAlreadyThere(ID, Type, ObjectIS)
	
	Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
	
	Query = New Query(
		"SELECT
		|	ObjectsIntegratedWith1CDocumentManagement.Object AS Object,
		|	ObjectsIntegratedWith1CDocumentManagement.ObjectTypeDM AS ObjectTypeDM,
		|	ObjectsIntegratedWith1CDocumentManagement.ObjectIDDM AS ObjectIDDM
		|FROM
		|	InformationRegister.ObjectsIntegratedWith1CDocumentManagement AS ObjectsIntegratedWith1CDocumentManagement
		|WHERE
		|	ObjectsIntegratedWith1CDocumentManagement.Object = &Object
		|	AND ObjectsIntegratedWith1CDocumentManagement.ObjectIDDM = &ObjectIDDM");
	Query.SetParameter("Object", ObjectIS);
	Query.SetParameter("ObjectIDDM", ID);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		If Selection.ObjectTypeDM = Type Then
			Return True;
		EndIf;
		
		If Settings.UseIntegrationBefore3 Then
			ModuleIntegrationWith1CDocumentManagement3 = Common.CommonModule("IntegrationWith1CDocumentManagement3");
			If ModuleIntegrationWith1CDocumentManagement3.IsDocumentBefore3(Selection.ObjectTypeDM)
					And ModuleIntegrationWith1CDocumentManagement3.IsDocumentBefore3(Type) Then
				Return True;
			EndIf;
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

#EndRegion

#EndIf