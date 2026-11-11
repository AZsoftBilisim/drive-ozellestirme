#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	AbbreviatedNameOfConfiguration =
		IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration();
	If ValueIsFilled(AbbreviatedNameOfConfiguration) Then
		NoteTemplate = NStr(
			"vi = 'Sẽ thêm các tham chiếu bị thiếu đến đối tượng %1 vào cơ sở 1C:Document Management.
			|Sẽ thêm các tham chiếu bị thiếu đến đối tượng của 1C:Document Management vào cơ sở %1.
			|Chú ý, thao tác có thể mất nhiều thời gian. Trong thời gian thực hiện thao tác, tích hợp liền mạch với 1C:Document Management sẽ bị hạn chế.';
			|ru = 'В базу 1С:Документооборот будут добавлены недостающие ссылки на объекты %1.
			|В базу %1 будут добавлены недостающие ссылки на объекты 1С:Документооборота.
			|Внимание, операция может занять продолжительное время. Во время выполнения операции бесшовная интеграция с 1С:Документооборотом будет ограничена.';
			|en = 'Missing links to %1 objects will be added to 1C:Document Management.
			|The missing links to 1C:Document Management objects will be added to %1.
			|The operation might take a long time. During the operation, seamless integration with 1C:Document Management will be limited.'; fa = 'Missing links to %1 objects will be added to 1C:Document Management.
			|The missing links to 1C:Document Management objects will be added to %1.
			|The operation might take a long time. During the operation, seamless integration with 1C:Document Management will be limited.';
			|it = 'В базу 1С:Документооборот будут добавлены недостающие ссылки на объекты %1.
			|В базу %1 будут добавлены недостающие ссылки на объекты 1С:Документооборота.
			|Внимание, операция может занять продолжительное время. Во время выполнения операции бесшовная интеграция с 1С:Документооборотом будет ограничена.';
			|pl = 'Missing links to %1 objects will be added to 1C:Document Management.
			|The missing links to 1C:Document Management objects will be added to %1.
			|The operation might take a long time. During the operation, seamless integration with 1C:Document Management will be limited.';
			|tr = '%1 nesnelerine yönelik eksik bağlantılar 1C:Document Management tabanına eklenecektir.
			|1C:Document Management nesnelerine yönelik eksik bağlantılar %1 tabanına eklendi.
			|Dikkat, işlem uzun sürebilir. İşlem sırasında 1C:Document Management ile sorunsuz entegrasyon sınırlı olacaktır.'");
		
		Items.Explanation.Title = StrTemplate(NoteTemplate, AbbreviatedNameOfConfiguration);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	TestConnection();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Not IsOpen() Then
		Return;
	EndIf;
	
	If EventName = "IntegrationWith1CDocumentManagement_SuccessfulConnection" And Source <> ThisObject Then
		WhenConnecting();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AuthorizationSettingsDecorationClick(Item)
	
	Notification = New CallbackDescription("AuthorizationSettingsDecorationClickCompletion", ThisObject);
	NameOfParameterForm = "DataProcessor.IntegrationWith1CDocumentManagementCore.Form.AuthorizationIn1CDocumentManagement";
	
	FormParameters = New Structure;
	FormParameters.Insert("ConnectingToCentralSubAsset", True);
	
	OpenForm(
		NameOfParameterForm,
		FormParameters,
		ThisObject,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AuthorizationSettingsDecorationClickCompletion(Result, Var_Parameters) Export
	
	If Result = True Then
		WhenConnecting();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Synchronize(Command)
	
	If OperationCompleted Then
		Close(New Structure("ExcessiveLinksBefore, ExtraIPLinks", ExcessiveLinksBefore, ExtraIPLinks));
		Return;
	EndIf;
	
	ExcessiveLinksBefore.Clear();
	ExtraIPLinks.Clear();
	OperationCompleted = False;
	
	StartSync();
	
EndProcedure

#EndRegion

#Region Private

#Region StartSync

&AtClient
Procedure StartSync()
	
	TimeConsumingOperation = StartSynchronizationOnServer();
	If TimeConsumingOperation = Undefined Then
		Return;
	EndIf;
	
	Items.Synchronize.Enabled = False;
	CurrentStatus = NStr("vi = 'Chuẩn bị dữ liệu để thực hiện thao tác';
						|ru = 'Подготовка данных для выполнения операции';
						|en = 'Prepare data to perform the operation'; fa = 'Prepare data to perform the operation';
						|it = 'Подготовка данных для выполнения операции';
						|pl = 'Prepare data to perform the operation';
						|tr = 'İşlemin gerçekleştirilmesi için verilerin hazırlanması'");
	Progress = 0;
	
	CallbackOnCompletion = New CallbackDescription("StartSyncCompletion", ThisObject);
	IntegrationWith1CDocumentManagementCoreClient.ExecuteRequestAsynchronously(
		ThisObject,
		TimeConsumingOperation,
		CallbackOnCompletion,,,
		False);
	
EndProcedure

&AtServer
Function StartSynchronizationOnServer()
	
	Try
		
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy(
			True,
			AddressOf1CDocumentManagementWebService());
		
		Query = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			"DMClearFeedbackMarkInObjectLinksRequest");
		
		Return IntegrationWith1CDocumentManagementCore.ExecuteRequestAsynchronously(
			Proxy,
			Query,
			UUID,
			NStr("vi = 'Chuẩn bị dữ liệu để đồng bộ hóa các liên kết';
				|ru = 'Подготовка данных для синхронизации связей';
				|en = 'Prepare data to synchronize links'; fa = 'Prepare data to synchronize links';
				|it = 'Подготовка данных для синхронизации связей';
				|pl = 'Prepare data to synchronize links';
				|tr = 'Bağlantı senkronizasyonu için verilerin hazırlanması'"));
		
	Except
		
		HandleException(ErrorInfo());
		
	EndTry;
	
EndFunction

&AtClient
Procedure StartSyncCompletion(Result, NotificationParameters) Export
	
	Items.Synchronize.Enabled = True;
	
	If Result = Undefined Then
		CurrentStatus = "";
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		
		ResultOfStartOfSynchronization = StartSynchronizationOnServerCompletion(Result.ResultLongOperation);
		If ResultOfStartOfSynchronization.Success Then
			RunSync();
		Else
			HandleException(ResultOfStartOfSynchronization.WarningText);
		EndIf;
		
	ElsIf Result.Status = "Error" Then
		
		HandleException(Result.BriefErrorDescription);
		
	EndIf;
	
EndProcedure

&AtServer
Function StartSynchronizationOnServerCompletion(ResponseToRequestIsString)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	ResponseToRequest = IntegrationWith1CDocumentManagementCore.StringInXDTOObject(
		Proxy,
		ResponseToRequestIsString);
	
	Result = New Structure("Success, WarningText", True, "");
	
	If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, ResponseToRequest, "DMError") Then
		Result.Success = False;
		Result.WarningText = StrTemplate(
			"%1
			|
			|%2",
			TrimAll(ResponseToRequest.subject),
			TrimAll(ResponseToRequest.description));
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region RunSync

&AtClient
Procedure RunSync()
	
	IntegratedObjects_ = IntegratedObjects_();
	ObjectCount = IntegratedObjects_.Count();
	
	If ObjectCount = 0 Then
		EndSyncing();
		Return;
	EndIf;
	
	IndexOf = 0;
	PortionSize = 500;
	
	SynchronizePortionOfObjects(IntegratedObjects_, ObjectCount, IndexOf, PortionSize);
	
EndProcedure

&AtClient
Procedure SynchronizePortionOfObjects(IntegratedObjects_, ObjectCount, IndexOf, PortionSize)
	
	Progress = Round((100 * IndexOf) / ObjectCount);
	
	If IndexOf = ObjectCount Then
		EndSyncing();
		Return;
	EndIf;
	
	TimeConsumingOperation = SynchronizePortionOfObjectsOnServer(
		IntegratedObjects_,
		ObjectCount,
		IndexOf,
		PortionSize);
	If TimeConsumingOperation = Undefined Then
		Return;
	EndIf;
	
	Items.Synchronize.Enabled = False;
	CurrentStatus = NStr("vi = 'Thực hiện thao tác';
						|ru = 'Выполнение операции';
						|en = 'Performing operation'; fa = 'در حال اجرای عملیات';
						|it = 'Svolgimento dell''operazione';
						|pl = 'Wykonanie operacji';
						|tr = 'İşlemin gerçekleştirilmesi'");
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("IntegratedObjects_", IntegratedObjects_);
	NotificationParameters.Insert("ObjectCount", ObjectCount);
	NotificationParameters.Insert("IndexOf", IndexOf);
	NotificationParameters.Insert("PortionSize", PortionSize);
	CallbackOnCompletion = New CallbackDescription(
		"SynchronizePortionOfObjectsCompletion",
		ThisObject,
		NotificationParameters);
	IntegrationWith1CDocumentManagementCoreClient.ExecuteRequestAsynchronously(
		ThisObject,
		TimeConsumingOperation,
		CallbackOnCompletion,,,
		False);
	
EndProcedure

&AtServer
Function SynchronizePortionOfObjectsOnServer(IntegratedObjects_, ObjectCount, IndexOf, PortionSize)
	
	Try
		
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		
		Query = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			"DMSynchronizeObjectLinksRequest");
		XDTOConnections = Query.links; // XDTOList
		
		For IndexOf = IndexOf To (IndexOf + PortionSize - 1) Do
			If IndexOf > (ObjectCount - 1) Then
				Break;
			EndIf;
			
			IPCommunication = IntegratedObjects_[IndexOf];
			
			XDTOConnections.Add(
				IntegrationWith1CDocumentManagementCore.CreateDMLink(
					Proxy,
					IPCommunication.ObjectIDDM,
					IPCommunication.ObjectTypeDM,
					IPCommunication.ObjectIS));
		EndDo;
		
		Return IntegrationWith1CDocumentManagementCore.ExecuteRequestAsynchronously(
			Proxy,
			Query,
			UUID,
			NStr("vi = 'Đồng bộ hóa liên kết';
				|ru = 'Синхронизация связей';
				|en = 'Link synchronization'; fa = 'همگام‌سازی پیوند';
				|it = 'Синхронизация связей';
				|pl = 'Link synchronization';
				|tr = 'Bağlantı senkronizasyonu'"));
		
	Except
		
		HandleException(ErrorInfo());
		
	EndTry;
	
EndFunction

// Handler for notification about the End of operation.
//
// Parameters:
//   Resultsquery - See TimeConsumingOperations.ActionCompleted
//   NotificationParameters - Structure:
//     * IntegratedObjects_ - Array of Structure:
//       ** ObjectIS - AnyRef
//       ** ObjectIDDM - String
//       ** ObjectTypeDM - String
//     * ObjectCount - Number
//     * IndexOf - Number
//     * PortionSize - Number
//
&AtClient
Procedure SynchronizePortionOfObjectsCompletion(Result, NotificationParameters) Export
	
	Items.Synchronize.Enabled = True;
	
	If Result = Undefined Then
		CurrentStatus = "";
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		
		SynchronizationResult = SynchronizePortionOfObjectsOnServerCompletion(Result.ResultLongOperation);
		If SynchronizationResult.Success Then
			SynchronizePortionOfObjects(
				NotificationParameters.IntegratedObjects_,
				NotificationParameters.ObjectCount,
				NotificationParameters.IndexOf,
				NotificationParameters.PortionSize);
		Else
			HandleException(SynchronizationResult.WarningText);
		EndIf;
		
	ElsIf Result.Status = "Error" Then
		
		HandleException(Result.BriefErrorDescription);
		
	EndIf;
	
EndProcedure

&AtServer
Function SynchronizePortionOfObjectsOnServerCompletion(ResponseToRequestIsString)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	ResponseToRequest = IntegrationWith1CDocumentManagementCore.StringInXDTOObject(
		Proxy,
		ResponseToRequestIsString);
	
	Result = New Structure("Success, WarningText", True, "");
	
	If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, ResponseToRequest, "DMError") Then
		Result.Success = False;
		Result.WarningText = StrTemplate(
			"%1
			|
			|%2",
			TrimAll(ResponseToRequest.subject),
			TrimAll(ResponseToRequest.description));
	Else
		For Each XDTOConnection In ResponseToRequest.brokenLinks Do
			IPCommunication = ExtraIPLinks.Add();
			IPCommunication.ObjectIS = IntegrationWith1CDocumentManagementCore.LinkFromUUID(
				XDTOConnection.ownerObject.type,
				XDTOConnection.ownerObject.id);
			IPCommunication.ObjectIDDM = XDTOConnection.linkedObject.id;
			IPCommunication.ObjectTypeDM = XDTOConnection.linkedObject.type;
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region EndSyncing

&AtClient
Procedure EndSyncing()
	
	TimeConsumingOperation = CompleteSynchronizationOnServer();
	If TimeConsumingOperation = Undefined Then
		Return;
	EndIf;
	
	Items.Synchronize.Enabled = False;
	CurrentStatus = NStr("vi = 'Hoàn tất thực hiện thao tác';
						|ru = 'Завершение выполнения операции';
						|en = 'Complete operation execution'; fa = 'Complete operation execution';
						|it = 'Завершение выполнения операции';
						|pl = 'Complete operation execution';
						|tr = 'İşlemin tamamlanması'");
	Progress = 100;
	
	CallbackOnCompletion = New CallbackDescription("EndSyncingCompletion", ThisObject);
	IntegrationWith1CDocumentManagementCoreClient.ExecuteRequestAsynchronously(
		ThisObject,
		TimeConsumingOperation,
		CallbackOnCompletion,,,
		False);
	
EndProcedure

&AtServer
Function CompleteSynchronizationOnServer()
	
	Try
		
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		
		Query = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			"DMGetObjectLinksWithoutFeedbackMarkRequest");
		
		Return IntegrationWith1CDocumentManagementCore.ExecuteRequestAsynchronously(
			Proxy,
			Query,
			UUID,
			NStr("vi = 'Hoàn tất đồng bộ hóa các liên kết';
				|ru = 'Завершение синхронизации связей';
				|en = 'Complete link synchronization'; fa = 'Complete link synchronization';
				|it = 'Завершение синхронизации связей';
				|pl = 'Complete link synchronization';
				|tr = 'Bağlantı senkronizasyonunun tamamlanması'"));
		
	Except
		
		HandleException(ErrorInfo());
		
	EndTry;
	
EndFunction

&AtClient
Procedure EndSyncingCompletion(Result, NotificationParameters) Export
	
	Items.Synchronize.Enabled = True;
	
	If Result = Undefined Then
		CurrentStatus = "";
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		
		ResultOfEndOfSynchronization = CompleteSynchronizationOnServerCompletion(Result.ResultLongOperation);
		If ResultOfEndOfSynchronization.Success Then
			OperationCompleted = True;
			CurrentStatus = NStr("vi = 'Đã thực hiện thành công việc đồng bộ hóa';
								|ru = 'Синхронизация успешно выполнена';
								|en = 'Synchronization is completed successfully'; fa = 'Synchronization is completed successfully';
								|it = 'Синхронизация успешно выполнена';
								|pl = 'Synchronization is completed successfully';
								|tr = 'Senkronizasyon başarıyla tamamlandı'");
			Items.Synchronize.Title = NStr("vi = 'Kết thúc';
											|ru = 'Завершить';
											|en = 'Finish'; fa = 'پایان';
											|it = 'Завершить';
											|pl = 'Finish';
											|tr = 'Tamamla'");
		Else
			HandleException(ResultOfEndOfSynchronization.WarningText);
		EndIf;
		
	ElsIf Result.Status = "Error" Then
		
		HandleException(Result.BriefErrorDescription);
		
	EndIf;
	
EndProcedure

&AtServer
Function CompleteSynchronizationOnServerCompletion(ResponseToRequestIsString)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	ResponseToRequest = IntegrationWith1CDocumentManagementCore.StringInXDTOObject(
		Proxy,
		ResponseToRequestIsString);
	
	Result = New Structure("Success, WarningText", True, "");
	
	If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, ResponseToRequest, "DMError") Then
		Result.Success = False;
		Result.WarningText = StrTemplate(
			"%1
			|
			|%2",
			TrimAll(ResponseToRequest.subject),
			TrimAll(ResponseToRequest.description));
	Else
		
		AddedLinks = New Map;
		
		For Each XDTOConnection In ResponseToRequest.links Do
			
			IPObjectWasNotFound = False;
			
			Try
				ObjectReferenceIS = IntegrationWith1CDocumentManagementCore.LinkFromUUID(
					XDTOConnection.ownerObject.type,
					XDTOConnection.ownerObject.ID);
			Except
				IPObjectWasNotFound = True;
			EndTry;
			
			If (IPObjectWasNotFound = False)
					And (ObjectReferenceIS = Undefined
						Or Not Common.RefExists(ObjectReferenceIS)) Then
				IPObjectWasNotFound = True;
			EndIf;
			
			If IPObjectWasNotFound Then
				LinkBefore = ExcessiveLinksBefore.Add();
				LinkBefore.ObjectBefore = XDTOConnection.linkedObject.navigationRef;
				LinkBefore.ObjectPresentationDM = XDTOConnection.linkedObject.presentation;
				LinkBefore.ObjectIDDM = XDTOConnection.linkedObject.id;
				LinkBefore.ObjectTypeDM = XDTOConnection.linkedObject.type;
				LinkBefore.IdOfIPObject = XDTOConnection.ownerObject.id;
				LinkBefore.ObjectTypeIS = XDTOConnection.ownerObject.type;
				Continue;
			EndIf;
			
			BeginTransaction();
			Try
				DataLock = New DataLock;
				DataLockItem = DataLock.Add(
					"InformationRegister.ObjectsIntegratedWith1CDocumentManagement");
				DataLockItem.SetValue("ObjectTypeDM", XDTOConnection.linkedObject.type);
				DataLockItem.SetValue("ObjectIDDM", XDTOConnection.linkedObject.id);
				DataLockItem.Mode = DataLockMode.Exclusive;
				DataLock.Lock();
				
				RecordSet = InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.CreateRecordSet();
				RecordSet.Filter.ObjectTypeDM.Set(XDTOConnection.linkedObject.type);
				RecordSet.Filter.ObjectIDDM.Set(XDTOConnection.linkedObject.id);
				RecordSet.Read();
				For Each Record In RecordSet Do
					If Not ValueIsFilled(Record.Object) Then
						// An existing DO object should not refer to an empty IC object.
						RecordSet.Delete(Record);
					EndIf;
				EndDo;
				RecordSet.Write();
				
				CommitTransaction();
			Except
				RollbackTransaction();
				IntegrationWith1CDocumentManagementCore.WriteError(
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				Raise;
			EndTry;
			
			InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.AddLink(
				XDTOConnection.linkedObject.id,
				XDTOConnection.linkedObject.type,
				ObjectReferenceIS,
				False);
			AddedLinks.Insert(ObjectReferenceIS, XDTOConnection.linkedObject);
			
		EndDo;
		
		If AddedLinks.Count() > 0 Then
			// An additional request is required to correctly fill in
			// the There is a return link in the node on the 1C side:Document management.
			PackageQueries = New Array;
			For Each AddedConnection In AddedLinks Do
				CommunicationRequest = IntegrationWith1CDocumentManagementCore.CreateObject(
					Proxy,
					"DMAddObjectLinkRequest");
				CommunicationRequest.ownerObject = IntegrationWith1CDocumentManagementCore.CreateExternalObject(
					Proxy,
					AddedConnection.Key);
				CommunicationRequest.linkedObject = AddedConnection.Value;
				PackageQueries.Add(CommunicationRequest);
			EndDo;
			IntegrationWith1CDocumentManagementCore.ExecuteBatchRequest(Proxy, PackageQueries, True);
		EndIf;
		
		BeginTransaction();
		Try
			DataLock = New DataLock;
			DataLockItem = DataLock.Add(
				"InformationRegister.ObjectsIntegratedWith1CDocumentManagement");
			DataLockItem.SetValue("Object", Undefined);
			DataLockItem.SetValue("ObjectTypeDM", "");
			DataLockItem.SetValue("ObjectIDDM", "");
			DataLockItem.Mode = DataLockMode.Exclusive;
			DataLock.Lock();
			
			QueryEmptyLinks = New Query(
				"SELECT
				|	ObjectsIntegratedWith1CDocumentManagement.Object AS Object,
				|	ObjectsIntegratedWith1CDocumentManagement.ObjectTypeDM AS ObjectTypeDM,
				|	ObjectsIntegratedWith1CDocumentManagement.ObjectIDDM AS ObjectIDDM
				|FROM
				|	InformationRegister.ObjectsIntegratedWith1CDocumentManagement AS ObjectsIntegratedWith1CDocumentManagement
				|WHERE
				|	(ObjectsIntegratedWith1CDocumentManagement.Object = UNDEFINED
				|			OR ObjectsIntegratedWith1CDocumentManagement.ObjectTypeDM = """"
				|			OR ObjectsIntegratedWith1CDocumentManagement.ObjectIDDM = """")");
			Selection = QueryEmptyLinks.Execute().Select();
			While Selection.Next() Do
				If Not ValueIsFilled(Selection.ObjectIDDM) Or Not ValueIsFilled(Selection.ObjectTypeDM) Then
					If ValueIsFilled(Selection.Object) Then
						IPCommunication = ExtraIPLinks.Add();
						IPCommunication.ObjectIS = Selection.Object;
						IPCommunication.ObjectIDDM = Selection.ObjectIDDM;
						IPCommunication.ObjectTypeDM = Selection.ObjectTypeDM;
					Else
						// An irreplaceable connection.
						Record = InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.CreateRecordManager();
						FillPropertyValues(Record, Selection);
						Record.Delete();
					EndIf;
				EndIf;
			EndDo;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			IntegrationWith1CDocumentManagementCore.WriteError(
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Raise;
		EndTry;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

&AtServerNoContext
Function AddressOf1CDocumentManagementWebService()
	
	Return IntegrationWith1CDocumentManagementCore.AddressOf1CDocumentManagementWebService(True);
	
EndFunction

&AtServer
Function IntegratedObjects_()
	
	IntegratedObjects_ = New Array;
	
	QueryIntegratedObjects = New Query(
		"SELECT
		|	ObjectsIntegratedWith1CDocumentManagement.Object AS Object,
		|	ObjectsIntegratedWith1CDocumentManagement.ObjectTypeDM AS ObjectTypeDM,
		|	ObjectsIntegratedWith1CDocumentManagement.ObjectIDDM AS ObjectIDDM
		|FROM
		|	InformationRegister.ObjectsIntegratedWith1CDocumentManagement AS ObjectsIntegratedWith1CDocumentManagement
		|WHERE
		|	(ObjectsIntegratedWith1CDocumentManagement.ObjectTypeDM = ""DMDocument""
		|			OR ObjectsIntegratedWith1CDocumentManagement.ObjectTypeDM = ""DMInternalDocument""
		|			OR ObjectsIntegratedWith1CDocumentManagement.ObjectTypeDM = ""DMIncomingDocument""
		|			OR ObjectsIntegratedWith1CDocumentManagement.ObjectTypeDM = ""DMOutgoingDocument""
		|			OR ObjectsIntegratedWith1CDocumentManagement.ObjectTypeDM = ""DMCorrespondent""
		|			OR ObjectsIntegratedWith1CDocumentManagement.ObjectTypeDM = ""DMMeeting"")
		|	AND ObjectsIntegratedWith1CDocumentManagement.ObjectIDDM <> """"");
	
	AllRefsType = Metadata.DefinedTypes.IntegrationWith1CWorkflowAllLinksOverridable.Type;
	
	Selection = QueryIntegratedObjects.Execute().Select();
	While Selection.Next() Do
		If Not ValueIsFilled(Selection.Object) Or Not AllRefsType.ContainsType(TypeOf(Selection.Object)) Then
			Continue;
		EndIf;
		
		IntegratedObjects_.Add(
			IPCommunication(
				Selection.Object,
				Selection.ObjectIDDM,
				Selection.ObjectTypeDM));
	EndDo;
	
	Return IntegratedObjects_;
	
EndFunction

&AtClientAtServerNoContext
Function IPCommunication(ObjectIS, ObjectIDDM, ObjectTypeDM)
	
	IPCommunication = New Structure;
	IPCommunication.Insert("ObjectIS", ObjectIS);
	IPCommunication.Insert("ObjectIDDM", ObjectIDDM);
	IPCommunication.Insert("ObjectTypeDM", ObjectTypeDM);
	
	Return IPCommunication;
	
EndFunction

// Checks the connection to the DO by displaying the authorization window, if necessary, and changing the form according to the result.
//
&AtClient
Procedure TestConnection()
	
	CallbackDescription = New CallbackDescription("TestConnectionCompletion", ThisObject);
	IntegrationWith1CDocumentManagementCoreClient.TestConnection(
		CallbackDescription,
		ThisObject,,
		False,
		True,
		AddressOf1CDocumentManagementWebService());
	
EndProcedure

&AtClient
Procedure TestConnectionCompletion(Result, Var_Parameters) Export
	
	If Result = True Then
		WhenConnecting();
	Else // Couldn't connect to BEFORE.
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenConnecting()
	
	ProcessFormAccordingToServiceVersion();
	
EndProcedure

&AtServer
Function ProcessFormAccordingToServiceVersion()
	
	ServiceVersion = IntegrationWith1CDocumentManagementCore.ServiceVersion();
	
	If Not IntegrationWith1CDocumentManagementCoreClientServer.ServiceIsAvailable(ServiceVersion) Then
		Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsUnavailable;
		Return False;
	EndIf;
	
	FormProcessedSuccessfully = True;
	
	Try
		
		If IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("3.0.11.25") Then
			
			Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsAvailable;
			
		Else
			
			Items.ConnectionPageGroup.CurrentPage = Items.VersionPageIsNotSupported;
			FormProcessedSuccessfully = False;
			
		EndIf;
		
	Except
		
		HandleException(ErrorInfo());
		
	EndTry;
	
	Return FormProcessedSuccessfully;
	
EndFunction

&AtServer
Procedure HandleException(Val ErrorInfo)
	
	CurrentStatus = "";
	Progress = 0;
	
	If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(ErrorInfo) Then
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
EndProcedure

#EndRegion