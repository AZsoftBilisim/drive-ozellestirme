////////////////////////////////////////////////////////////////////////////////
// Subsystem "Integration with 1C:Document management"
// Module of integration1 Document management 3 Exchange, server, external connection
////////////////////////////////////////////////////////////////////////////////

#Region Public

// Places the changes in the database and returns a response to the DMILPutChangesRequest request.
//
// Parameters:
//   Message - XDTODataObject - XDTO object of type DMILPutChangesRequest:
//     * messageData - BinaryData
//
// Returns:
//   XDTODataObject - an XDTO object of the DMILPutChangesResponse or DMILError type.
//
Function RecordChangesToObjects(Message) Export
	
	EventName = NStr("vi = 'Nhận dữ liệu';
					|ru = 'Получение данных';
					|en = 'Get data'; fa = 'Get data';
					|it = 'Acquisizione dei dati';
					|pl = 'Pobieranie danych';
					|tr = 'Veri alımı'");
	
	Try
		
		ErrorsArray = New Array;
		ArrayOfExternalObjectsWithoutErrors = New Array;
		DocumentFlowNode = IntegrationWith1CDocumentManagementCoreCached.DocumentFlowNode();
		ExchangePlanContent = Metadata.ExchangePlans.IntegrationWith1CDocumentManagementSubsystemOverridable.Content;
		
		For Each XDTODataObject In IntegrationWith1CDocumentManagement3.ListOfXDTObjectsAboutMessage(Message.messageData) Do
			Try
				
				ExternalObject = IntegrationWith1CDocumentManagement3.CreateBIDObject("ExternalObjectID");
				
				If IntegrationWith1CDocumentManagementCore.ValidateType(
						Undefined, XDTODataObject, "DMApprovalStateRecord") Then
					
					ExternalObject.ID = XDTODataObject.ID;
					ExternalObject.type = "DMApprovalStateRecord";
					
					ErrorTitle = StrTemplate(
						NStr("vi = 'Lỗi khi kết nhập từ 1C:Document Management trạng thái ""%1"":
							|   * ID đối tượng 1C:Document Management: %2.
							|   * Kiểu đối tượng 1C:Document Management: %3.';
							|ru = 'Ошибка при загрузке из 1С:Документооборота статуса ""%1"":
							|   * Идентификатор объекта 1С:Документооборота: %2.
							|   * Тип объекта 1С:Документооборота: %3.';
							|en = 'An error occurred when importing the ""%1"" status from 1C:Document Management:
							|   * 1C:Document Management object ID: %2.
							|   * 1C:Document Management object type: %3.'; fa = 'An error occurred when importing the ""%1"" status from 1C:Document Management:
							|   * 1C:Document Management object ID: %2.
							|   * 1C:Document Management object type: %3.';
							|it = 'Ошибка при загрузке из 1С:Документооборота статуса ""%1"":
							|   * Идентификатор объекта 1С:Документооборота: %2.
							|   * Тип объекта 1С:Документооборота: %3.';
							|pl = 'An error occurred when importing the ""%1"" status from 1C:Document Management:
							|   * 1C:Document Management object ID: %2.
							|   * 1C:Document Management object type: %3.';
							|tr = '1C:DocumentManagement''tan ""%1"":
							|   * İş Akışı nesnesi tanımlayıcısı: %2.
							|   1C:DocumentManagement nesne türü: %3durumu indirme hatası.'",
							Common.DefaultLanguageCode()),
						XDTODataObject.status,
						XDTODataObject.ID,
						XDTODataObject.type);
					
					DownloadStateOfDocument(XDTODataObject);
					
				Else
					
					ExternalObject.ID = XDTODataObject.objectID.ID;
					ExternalObject.type = XDTODataObject.objectID.type;
					
					References = IntegrationWith1CDocumentManagementCore.LinksToExternalObjects(XDTODataObject);
					For Each ObjectRef In References Do
						ErrorTitle = StrTemplate(
							NStr("vi = 'Lỗi khi kết nhập dữ liệu từ đối tượng 1C:Document Management ""%1"":
								|   * Tham chiếu dẫn hướng đến đối tượng 1C:Document Management: %2.
								|   * Tham chiếu dẫn hướng đến đối tượng %3: %4.';
								|ru = 'Ошибка при загрузке данных из объекта 1С:Документооборота ""%1"":
								|   * Навигационная ссылка на объект 1С:Документооборота: %2.
								|   * Навигационная ссылка на объект %3: %4.';
								|en = 'An error occurred when importing data from 1C:Document Management object ""%1"":
								|   * 1C:Document Management object URL: %2.
								|   * The %3 object URL: %4.'; fa = 'An error occurred when importing data from 1C:Document Management object ""%1"":
								|   * 1C:Document Management object URL: %2.
								|   * The %3 object URL: %4.';
								|it = 'Ошибка при загрузке данных из объекта 1С:Документооборота ""%1"":
								|   * Навигационная ссылка на объект 1С:Документооборота: %2.
								|   * Навигационная ссылка на объект %3: %4.';
								|pl = 'An error occurred when importing data from 1C:Document Management object ""%1"":
								|   * 1C:Document Management object URL: %2.
								|   * The %3 object URL: %4.';
								|tr = '1C:Document Management nesnesinden veri yüklenirken hata""%1"":
								|   * 1C:Document Management nesnesine URL bağlantısı: %2.
								|   * Nesneye URL bağlantısı %3: %4.'",
								Common.DefaultLanguageCode()),
							XDTODataObject.name,
							XDTODataObject.objectID.navigationRef,
							IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration(),
							GetURL(ObjectRef));
						
						SuitableRules =
							IntegrationWith1CDocumentManagement3ServerCall.SuitableObjectIntegrationRules(
								ObjectRef,
								True);
						If SuitableRules = Undefined Or SuitableRules.Count() = 0 Then
							WarningText = StrTemplate(
								"%1
								|%2",
								ErrorTitle,
								NStr("vi = 'Không có quy tắc tích hợp';
									|ru = 'Отсутствуют правила интеграции';
									|en = 'Integration rules are missing'; fa = 'Integration rules are missing';
									|it = 'Integration rules are missing';
									|pl = 'Integration rules are missing';
									|tr = 'Entegrasyon kuralları yok'"));
							IntegrationWith1CDocumentManagementCore.WriteWarning(
								WarningText,
								EventName);
							Continue;
						ElsIf SuitableRules.Count() > 1 Then
							Raise StrTemplate(
								NStr("ru = 'Найдено более одного правила интеграции объекта ""%1"".
									|Невозможно однозначно определить единственное подходящее правило.
									|Нужно настроить условия применимости правил.';
									|vi = 'More than one integration rule for the ""%1"" object was found.
									|Cannot uniquely identify a single suitable rule.
									|The rules applicability conditions must be configured.';
									|en = 'More than one integration rule for the ""%1"" object was found.
									|Cannot uniquely identify a single suitable rule.
									|The rules applicability conditions must be configured.'; fa = 'More than one integration rule for the ""%1"" object was found.
									|Cannot uniquely identify a single suitable rule.
									|The rules applicability conditions must be configured.';
									|it = 'More than one integration rule for the ""%1"" object was found.
									|Cannot uniquely identify a single suitable rule.
									|The rules applicability conditions must be configured.';
									|pl = 'More than one integration rule for the ""%1"" object was found.
									|Cannot uniquely identify a single suitable rule.
									|The rules applicability conditions must be configured.';
									|tr = '""%1"" nesnesi için birden fazla entegrasyon kuralı bulundu. 
									| Tek bir uygun kural tam olarak belirlenemiyor.
									| Kuralların uygulanabilirlik koşullarının yapılandırılması gerekir.'"),
								ObjectRef);
						EndIf;
						Rule = SuitableRules[0];
						
						LoadReferenceObject(
							ObjectRef,
							Rule,
							XDTODataObject,
							DocumentFlowNode,
							ExchangePlanContent);
						
					EndDo;
					
				EndIf;
				
				ArrayOfExternalObjectsWithoutErrors.Add(ExternalObject);
				
			Except
				ErrorText = StrTemplate(
					"%1
					|%2",
					ErrorTitle,
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				ErrorsArray.Add(ErrorText);
				IntegrationWith1CDocumentManagementCore.WriteError(ErrorText, EventName);
			EndTry;
		EndDo;
		
		If ErrorsArray.Count() = 0 Then
			Return IntegrationWith1CDocumentManagement3.CreateBIDObject("DMILPutChangesResponse");
		Else
			Return IntegrationWith1CDocumentManagement3.DescriptionOfXDTOError(
				NStr("vi = 'Lỗi khi kết nhập thông điệp trao đổi từ 1C:Document Management';
					|ru = 'Ошибка при загрузке сообщения обмена из 1С:Документооборота';
					|en = 'An error occurred when importing the exchange message from 1C:Document Management'; fa = 'An error occurred when importing the exchange message from 1C:Document Management';
					|it = 'Ошибка при загрузке сообщения обмена из 1С:Документооборота';
					|pl = 'An error occurred when importing the exchange message from 1C:Document Management';
					|tr = '1C:Document Management''ten değişim mesajı yüklenirken hata'"),
				StrConcat(
					ErrorsArray,
					"
					|-----
					|
					|"),
				ArrayOfExternalObjectsWithoutErrors);
		EndIf;
		
	Except
		
		Return IntegrationWith1CDocumentManagement3.DescriptionOfXDTOError(
			NStr("vi = 'Lỗi khi kết nhập thông điệp trao đổi từ 1C:Document Management';
				|ru = 'Ошибка при загрузке сообщения обмена из 1С:Документооборота';
				|en = 'An error occurred when importing the exchange message from 1C:Document Management'; fa = 'An error occurred when importing the exchange message from 1C:Document Management';
				|it = 'Ошибка при загрузке сообщения обмена из 1С:Документооборота';
				|pl = 'An error occurred when importing the exchange message from 1C:Document Management';
				|tr = '1C:Document Management''ten değişim mesajı yüklenirken hata'"),
			IntegrationWith1CDocumentManagement3.GetErrorDescription(ErrorInfo()));
		
	EndTry;
	
EndFunction

// Returns a request to update the IP object data in UP to.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   ExternalObject - AnyRef - reference to the IP object.
//   ControlOverSendingFiles - See IntegrationWith1CDocumentManagementCore.ControlOverSendingFiles
//
// Returns:
//   XDTODataObject - an XDTO object of type DMUpdateFromIncomingDataRequest.
//   Undefined - if the IP object cannot be updated to, for example, due to the lack of a suitable rule.
//
Function RequestToUpdateObject(Proxy, ExternalObject, ControlOverSendingFiles) Export
	
	EventName = NStr("vi = 'Cập nhật dữ liệu đối tượng của hệ thống thông tin sang DM';
					|ru = 'Обновление данных объекта ИС в ДО';
					|en = 'Update IS object data in DI'; fa = 'Update IS object data in DI';
					|it = 'Update IS object data in DI';
					|pl = 'Update IS object data in DI';
					|tr = 'BY kapsamındaki ES nesnesinin verilerinin güncellenmesi'");
	
	ControlOverSendingFiles = IntegrationWith1CDocumentManagementCore.ControlOverSendingFiles();
	
	IntegratedObjects_ = ArrayOfDataToUpload(
		Proxy,
		CommonClientServer.ValueInArray(ExternalObject),
		EventName);
	If IntegratedObjects_.Count() <> 1 Then
		Return Undefined;
	EndIf;
	
	RequestToUpdateObject = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMUpdateFromIncomingDataRequest");
	ListOfObjectsToUpdate = RequestToUpdateObject.objects; // XDTOList
	
	ListOfObjectsToUpdate.Add(
		GetXDTOOfChangesFromObject(
			Proxy,
			IntegratedObjects_[0],
			ControlOverSendingFiles));
	
	Return RequestToUpdateObject;
	
EndFunction

// Returns modified objects integrated with 1C:Document management, and ready for upload.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   ExchangeNode - ExchangePlanRef.IntegrationWith1CDocumentManagementSubsystemOverridable - the node to
//     get the changes from.
//   ObjectsToDeleteFromChangeRegistration - Array of AnyRef - the implicitly returned value
//     contains references to objects that do not require unloading, and to successfully sent objects.
//   EventName - String - the name of the event for the GR.
//
// Returns:
//   Array of Structure:
//     * Object - AnyRef
//     * ObjectIDDM - String
//     * ObjectTypeDM - String
//     * ListOfTSToBeUnloaded - Array of String
//     * ListOfExpressions - XDTOList
//     * VDOLoadingRule - XDTODataObject
//     * FileFunctionalityIsAvailable - Boolean
//     * PrintForms - XDTOList
//     * TypesOfPrintedFormFiles - XDTOList
//     * CreatingLinksIsAvailable - Boolean
//     * LinksToCreation - Array of See IntegrationWith1CDocumentManagementCoreClientServer.ConnectionToCreation
//
Function RegisteredData(Proxy, ExchangeNode, ObjectsToDeleteFromChangeRegistration, EventName) Export
	
	SetPrivilegedMode(True);
	
	ListOfIPObjects = New Array;
	RelatedObjectsBefore = New Map;
	
	For Each ExchangePlanContentItem In ExchangeNode.Metadata().Content Do
		ChangeRequest = New Query;
		QueryText =
			"SELECT
			|	ChangesTable1.Ref AS Object,
			|	ISNULL(ObjectsIntegratedWith1CDocumentManagement.ObjectIDDM, """") AS ObjectIDDM,
			|	ISNULL(ObjectsIntegratedWith1CDocumentManagement.ObjectTypeDM, """") AS ObjectTypeDM
			|FROM
			|	&ChangesTable1 AS ChangesTable1
			|		LEFT JOIN InformationRegister.ObjectsIntegratedWith1CDocumentManagement AS ObjectsIntegratedWith1CDocumentManagement
			|		ON ChangesTable1.Ref = ObjectsIntegratedWith1CDocumentManagement.Object
			|WHERE
			|	ChangesTable1.Node = &ExchangeNode";
		ChangeRequest.Text = StrReplace(
			QueryText,
			"&ChangesTable1",
			StrTemplate("%1.%2",
				ExchangePlanContentItem.Metadata.FullName(),
				"Changes"));
		ChangeRequest.SetParameter("ExchangeNode", ExchangeNode);
		
		SelectionOfObjects = ChangeRequest.Execute().Select();
		
		While SelectionOfObjects.Next() Do
			If IntegrationWith1CDocumentManagementCore.ObjectDoesNotSupportExchange(SelectionOfObjects.ObjectTypeDM)
					And ValueIsFilled(SelectionOfObjects.ObjectIDDM) Then
				LinkedObject = New Structure("ObjectTypeDM, ObjectIDDM",
					SelectionOfObjects.ObjectTypeDM,
					SelectionOfObjects.ObjectIDDM);
				ListOfIPObjects.Add(SelectionOfObjects.Object);
				RelatedObjectsBefore.Insert(SelectionOfObjects.Object, LinkedObject);
			Else
				// You don't need to upload an object.
				ObjectsToDeleteFromChangeRegistration.Add(SelectionOfObjects.Object);
			EndIf;
			
		EndDo;
	EndDo;
	
	Return ArrayOfDataToUpload(
		Proxy,
		ListOfIPObjects,
		EventName,
		RelatedObjectsBefore,
		ObjectsToDeleteFromChangeRegistration);
	
EndFunction

// Returns an XDTO object containing the updated changes to the object.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   ObjectData - See IntegrationWith1CDocumentManagement3Exchange.RegisteredData
//   ControlOverSendingFiles - See IntegrationWith1CDocumentManagementCore.ControlOverSendingFiles
//
// Returns:
//   XDTODataObject
//
Function GetXDTOOfChangesFromObject(Proxy, ObjectData, ControlOverSendingFiles) Export
	
	ObjectCreationStructure = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMIncomingDataRequestStructure",
		ObjectData.Object);
	
	ObjectCreationStructure.incomingData = IntegrationWith1CDocumentManagement3.IncomingIPObjectData(
		Proxy,
		ObjectData.Object,
		ObjectData.ListOfTSToBeUnloaded,
		ObjectData.ListOfExpressions);
	
	ObjectCreationStructure.updatingObject = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		ObjectData.ObjectIDDM,
		ObjectData.ObjectTypeDM);
	
	ObjectCreationStructure.dataLoadingRule = ObjectData.VDOLoadingRule;
	
	If ObjectData.FileFunctionalityIsAvailable Then
		ListOfFiles = ObjectCreationStructure.files; // XDTOList
		PrintedFormsToCreate = IntegrationWith1CDocumentManagementCore.PrintedFormsToCreate(
			ObjectData.Object,
			IntegrationWith1CDocumentManagement3.AttachedPrintedForms(ObjectData.PrintForms),
			Enums.TypesOfSavedPrintedFormFileOfObjects[ObjectData.TypesOfPrintedFormFiles],
			ControlOverSendingFiles,
			True);
		For Each CreationParameters In PrintedFormsToCreate Do
			XDTOFile = IntegrationWith1CDocumentManagementCore.XDTOFileFromCreationParameters(
				Proxy,
				CreationParameters);
			ListOfFiles.Add(XDTOFile);
		EndDo;
	EndIf;
	
	If ObjectData.CreatingLinksIsAvailable Then
		IntegrationWith1CDocumentManagement3.TransferLinksToBeCreatedToIncomingDataStructure(
			Proxy,
			ObjectData.LinksToCreation,
			ObjectCreationStructure);
	EndIf;
	
	Return ObjectCreationStructure;
	
EndFunction

#EndRegion

#Region Private

Procedure DownloadStateOfDocument(XDTODataObject)
	
	RelatedObjectRequest = New Query(
		"SELECT TOP 1
		|	Object
		|FROM
		|	InformationRegister.ObjectsIntegratedWith1CDocumentManagement
		|WHERE
		|	ObjectTypeDM = &ObjectTypeDM
		|	AND ObjectIDDM = &ObjectIDDM");
	RelatedObjectRequest.SetParameter("ObjectTypeDM", XDTODataObject.type);
	RelatedObjectRequest.SetParameter("ObjectIDDM", XDTODataObject.ID);
	
	Selection = RelatedObjectRequest.Execute().Select();
	If Not Selection.Next() Then
		Return;
	EndIf;
	
	Try
		If XDTODataObject.status = Undefined Then // The record has been deleted (for example, an interrupt).
			Action = NStr("vi = 'Xóa trạng thái';
							|ru = 'Удаление статуса';
							|en = 'Delete status'; fa = 'حذف وضعیت';
							|it = 'Eliminazione stato';
							|pl = 'Usunięcie statusu';
							|tr = 'Durum silme'", Common.DefaultLanguageCode());
			IntegrationWith1CDocumentManagementCoreServerCall.WhenApprovalStateChanges(
				XDTODataObject.ID,
				XDTODataObject.type,
				Undefined,
				False,
				Selection.Object);
		Else
			Action = NStr("vi = 'Đặt trạng thái';
							|ru = 'Установка статуса';
							|en = 'Set status'; fa = 'تعیین وضعیت';
							|it = 'Impostazione dello stato';
							|pl = 'Ustawianie statusu';
							|tr = 'Durumun ayarlanması'", Common.DefaultLanguageCode());
			State = Enums.ApprovalStatesIn1CDocumentManagement.ValueCorrespondingToStatusDM(
				XDTODataObject.status);
			IntegrationWith1CDocumentManagementCoreServerCall.WhenApprovalStateChanges(
				XDTODataObject.ID,
				XDTODataObject.type,
				State,
				False,
				Selection.Object,
				XDTODataObject.name,
				XDTODataObject.date);
		EndIf;
	Except
		Raise StrTemplate(NStr("vi = 'Thao tác: %1.
									|%2';
									|ru = 'Действие: %1.
									|%2';
									|en = 'Action: %1.
									|%2'; fa = 'Action: %1.
									|%2';
									|it = 'Azione: %1.
									|%2';
									|pl = 'Czynność: %1.
									|%2';
									|tr = 'Eylem: %1.
									|%2'", Common.DefaultLanguageCode()),
			Action,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

Procedure LoadReferenceObject(ObjectRef, Rule, XDTODataObject, DocumentFlowNode, ExchangePlanContent)
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "files") Then
		
		If XDTODataObject.files.Count() > 0 Then
			IntegrationWith1CDocumentManagementCore.OnAdd1CDocumentManagementAttachedFiles(
				XDTODataObject.objectID.ID,
				XDTODataObject.objectID.type,
				ObjectRef,
				True);
		Else
			IntegrationWith1CDocumentManagementCore.OnRemove1CDocumentManagementAttachedFiles(
				XDTODataObject.objectID.ID,
				XDTODataObject.objectID.type,
				ObjectRef);
		EndIf;
		
	EndIf;
	
	If IntegrationWith1CDocumentManagement3.FileFunctionalityIsAvailable() Then
		InformationRegisters.PreparationForUpdatingPrintedForms.Add(ObjectRef, Rule);
	EndIf;
	
	Object = ObjectRef.GetObject();
	
	OriginalDeletionMark = Object.DeletionMark;
	RefreshEnabled = True;
	RequiresRecheck = False;
	
	HasChanges = Catalogs.RulesForIntegrationWith1CDocumentManagement3.FillInICObjectByXDTOObject(
		Undefined,
		Object,
		XDTODataObject,
		Rule,
		RefreshEnabled,
		RequiresRecheck);
	
	If Not HasChanges Then
		Return;
	EndIf;
	
	FillingCheckError = "";
	
	Try
		
		Action = NStr("vi = 'Lưu các thay đổi';
						|ru = 'Сохранение изменений';
						|en = 'Save the changes'; fa = 'Save the changes';
						|it = 'Сохранение изменений';
						|pl = 'Save the changes';
						|tr = 'Değişiklikleri kaydedilmesi'", Common.DefaultLanguageCode());
		
		If Object.DeletionMark And Not OriginalDeletionMark Then
			
			Object.Lock();
			
			ObjectMetadata = Object.Metadata();
			If Metadata.Documents.Contains(ObjectMetadata)
					And ObjectMetadata.Posting = Metadata.ObjectProperties.Posting.Allow
					And Object.Posted Then
				
				Action = NStr("vi = 'Xóa có hủy kết chuyển';
								|ru = 'Удаление с отменой проведения';
								|en = 'Delete and cancel posting'; fa = 'Delete and cancel posting';
								|it = 'Eliminazione con annullamento di pubblicazione';
								|pl = 'Usunięcie z anulowaniem zatwierdzenia';
								|tr = 'Kayıt ile silme'",
					Common.DefaultLanguageCode());
				
				Cancel = False;
				WriteMode = DocumentWriteMode.UndoPosting;
				IntegrationWith1CDocumentManagementCore.BeforeRecordingICObject(
					Object,
					Cancel,
					WriteMode);
				If Not Cancel Then
					Object.Write(WriteMode);
				EndIf;
				
			Else
				
				Action = NStr("vi = 'Xóa bỏ';
								|ru = 'Удаление';
								|en = 'Delete'; fa = 'حذف';
								|it = 'Eliminazione';
								|pl = 'Usunięcie';
								|tr = 'Silme'", Common.DefaultLanguageCode());
				Object.DataExchange.Load = True;
				
				Cancel = False;
				IntegrationWith1CDocumentManagementCore.BeforeRecordingICObject(
					Object,
					Cancel);
				If Not Cancel Then
					Object.Write();
				EndIf;
				
			EndIf;
			
			Object.Unlock();
			
		Else
			
			If Object.CheckFilling() Then
				
				Object.Lock();
				
				If RequiresRecheck Then
					
					Action = NStr("vi = 'Kết chuyển';
									|ru = 'Проведение';
									|en = 'Posting'; fa = 'ثبت در دفاتر';
									|it = 'Svolgimento';
									|pl = 'Księgowanie';
									|tr = 'Kaydetme'", Common.DefaultLanguageCode());
					
					Cancel = False;
					WriteMode = DocumentWriteMode.Posting;
					PostingMode = DocumentPostingMode.Regular;
					IntegrationWith1CDocumentManagementCore.BeforeRecordingICObject(
						Object,
						Cancel,
						WriteMode,
						PostingMode);
					If Not Cancel Then
						Object.Write(WriteMode, PostingMode);
					EndIf;
					
				Else
					
					Action = NStr("vi = 'Ghi lại';
									|ru = 'Запись';
									|en = 'Record'; fa = 'ثبت';
									|it = 'Registrazione';
									|pl = 'Zapis';
									|tr = 'Kayıt'", Common.DefaultLanguageCode());
					Object.DataExchange.Load = True;
					
					Cancel = False;
					IntegrationWith1CDocumentManagementCore.BeforeRecordingICObject(
						Object,
						Cancel);
					If Not Cancel Then
						Object.Write();
					EndIf;
					
				EndIf;
				
				Object.Unlock();
				
			Else
				
				UserMessages = GetUserMessages(True);
				MessageText = New Array;
				MessageText.Add(
					NStr("vi = 'Lỗi điền:';
						|ru = 'Ошибка заполнения:';
						|en = 'Filling error:'; fa = 'Filling error:';
						|it = 'Errore di compilazione:';
						|pl = 'Błąd wypełnienia:';
						|tr = 'Doldurma hatası:'", Common.DefaultLanguageCode()));
				For Each UserMessage In UserMessages Do
					MessageText.Add(UserMessage.Text);
				EndDo;
				FillingCheckError = StrConcat(MessageText, Chars.LF);
				
			EndIf;
			
		EndIf;
		
	Except
		Raise StrTemplate(NStr("vi = 'Thao tác: %1.
									|%2';
									|ru = 'Действие: %1.
									|%2';
									|en = 'Action: %1.
									|%2'; fa = 'Action: %1.
									|%2';
									|it = 'Azione: %1.
									|%2';
									|pl = 'Czynność: %1.
									|%2';
									|tr = 'Eylem: %1.
									|%2'", Common.DefaultLanguageCode()),
			Action,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	If FillingCheckError <> "" Then
		Raise FillingCheckError;
	EndIf;
	
	If ExchangePlanContent.Contains(Object.Metadata()) Then
		ExchangePlans.DeleteChangeRecords(DocumentFlowNode, Object.Ref);
	EndIf;
	
EndProcedure

// Returns an array of data prepared for uploading to 1C:Document flow.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   ListOfIPObjects - Array of AnyRef - a list of IP objects whose changes need to be sent to the DO.
//   EventName - String - the name of the event for the GR.
//   RelatedObjectsBefore - Map of KeyAndValue:
//     * Key - AnyRef - the IP object.
//     * Value - Structure:
//         ** ObjectTypeDM - String - the object type is UP TO.
//         ** ObjectIDDM - String - the ID of the object BEFORE.
//   ObjectsToDeleteFromChangeRegistration - Array of AnyRef - the implicitly returned value
//     contains references to objects that do not require unloading, and to successfully sent objects.
//
// Returns:
//   Array of Structure:
//     * Object - AnyRef
//     * ObjectIDDM - String
//     * ObjectTypeDM - String
//     * ListOfTSToBeUnloaded - Array of String
//     * ListOfExpressions - XDTOList
//     * VDOLoadingRule - XDTODataObject
//     * FileFunctionalityIsAvailable - Boolean
//     * PrintForms - XDTOList
//     * TypesOfPrintedFormFiles - XDTOList
//     * CreatingLinksIsAvailable - Boolean
//     * LinksToCreation - Array of See IntegrationWith1CDocumentManagementCoreClientServer.ConnectionToCreation
//
Function ArrayOfDataToUpload(Proxy, ListOfIPObjects, EventName, RelatedObjectsBefore = Undefined,
		ObjectsToDeleteFromChangeRegistration = Undefined)
	
	DataArray = New Array;
	
	SuitableIntegrationRules = IntegrationWith1CDocumentManagement3ServerCall.SuitableIntegrationRules(
		ListOfIPObjects,
		True);
	PreliminaryData = IntegrationWith1CDocumentManagement3.PreliminaryDataForUnloadingVDO(
		Proxy,
		ListOfIPObjects,
		SuitableIntegrationRules,,
		False);
	
	// We will add to the upload those IC objects for which there is a suitable rule for uploading to the DO.
	For Each ObjectIS In ListOfIPObjects Do
		
		VDOLoadingRule = IntegrationWith1CDocumentManagement3.RuleForLoadingVDOSFromPreliminaryData(
			Proxy,
			PreliminaryData,
			ObjectIS);
		If VDOLoadingRule = Undefined Then
			If SuitableIntegrationRules[ObjectIS] = Undefined
					Or SuitableIntegrationRules[ObjectIS].Count() = 0 Then
				WarningText = StrTemplate(
					NStr("vi = 'Đối tượng ""%1"" (%2) đã được ghi nhận vào trao đổi dữ liệu với đối tượng liên kết trong 1C:Document Management,
						|nhưng không có quy tắc tích hợp.';
						|ru = 'Объект ""%1"" (%2) зарегистрирован к обмену данными со связанным объектом в 1С:Документооборот,
						|но правила интеграции отсутствуют.';
						|en = 'The ""%1"" (%2) object is registered to exchange data with the related object in 1C:Document Management,
						|but integration rules are missing.'; fa = 'The ""%1"" (%2) object is registered to exchange data with the related object in 1C:Document Management,
						|but integration rules are missing.';
						|it = 'The ""%1"" (%2) object is registered to exchange data with the related object in 1C:Document Management,
						|but integration rules are missing.';
						|pl = 'The ""%1"" (%2) object is registered to exchange data with the related object in 1C:Document Management,
						|but integration rules are missing.';
						|tr = '""%1"" (%2) nesnesi, 1C:Document Management ile ilişkili nesneyle veri değişimi için kaydedildi,
						|ancak entegrasyon kuralları bulunmamaktadır.'"),
					ObjectIS,
					TypeOf(ObjectIS));
				IntegrationWith1CDocumentManagementCore.WriteWarning(
					WarningText,
					EventName,
					ObjectIS);
				If TypeOf(ObjectsToDeleteFromChangeRegistration) = Type("Array") Then
					ObjectsToDeleteFromChangeRegistration.Add(ObjectIS);
				EndIf;
			Else
				ErrorText = StrTemplate(
					NStr("vi = 'Đối tượng ""%1"" (%2) đã được ghi nhận vào trao đổi dữ liệu với đối tượng liên quan trong 1C:Document Management,
						|nhưng không tìm thấy quy tắc kết nhập dữ liệu phù hợp trong 1C:Document Management.';
						|ru = 'Объект ""%1"" (%2) зарегистрирован к обмену данными со связанным объектом в 1С:Документооборот,
						|но не найдено подходящее правило загрузки данных в 1С:Документооборот.';
						|en = 'The ""%1"" (%2) object is registered to exchange data with the related object in 1C:Document Management.
						|However, no suitable data import rules are found.'; fa = 'The ""%1"" (%2) object is registered to exchange data with the related object in 1C:Document Management.
						|However, no suitable data import rules are found.';
						|it = 'Объект ""%1"" (%2) зарегистрирован к обмену данными со связанным объектом в 1С:Документооборот,
						|но не найдено подходящее правило загрузки данных в 1С:Документооборот.';
						|pl = 'The ""%1"" (%2) object is registered to exchange data with the related object in 1C:Document Management.
						|However, no suitable data import rules are found.';
						|tr = '""%1"" (%2) nesnesi, 1C:Document Management ile ilişkili nesneyle veri değişimi için kaydedildi,
						|ancak 1C:Document Management''ta uygun veri yükleme kuralı bulunamadı.'"),
					ObjectIS,
					TypeOf(ObjectIS));
				IntegrationWith1CDocumentManagementCore.WriteError(ErrorText, EventName, ObjectIS);
			EndIf;
			
			Continue;
		EndIf;
		
		IntegratedObject = New Structure("Object", ObjectIS);
		
		If RelatedObjectsBefore = Undefined Then
			LinkedObjectBefore =
				InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.ObjectDataUpToExternalObject(ObjectIS);
			If LinkedObjectBefore = Undefined Then
				Raise StrTemplate(
					NStr("vi = 'Đối tượng ""%1"" (%2) không liên kết với đối tượng nào trong 1C:Document Management.';
						|ru = 'Объект ""%1"" (%2) не связан ни с каким объектом в 1С:Документообороте.';
						|en = 'The ""%1""(%2) object is not linked to any object in 1C:Document Management.'; fa = 'The ""%1""(%2) object is not linked to any object in 1C:Document Management.';
						|it = 'The ""%1""(%2) object is not linked to any object in 1C:Document Management.';
						|pl = 'The ""%1""(%2) object is not linked to any object in 1C:Document Management.';
						|tr = '""%1"" (%2) nesnesi, 1C:Document Management''teki hiçbir nesneye bağlı değil.'"),
					ObjectIS,
					TypeOf(ObjectIS));
			EndIf;
			IntegratedObject.Insert("ObjectIDDM", LinkedObjectBefore.ID);
			IntegratedObject.Insert("ObjectTypeDM", LinkedObjectBefore.type);
		Else
			IntegratedObject.Insert("ObjectIDDM", RelatedObjectsBefore[ObjectIS].ObjectIDDM);
			IntegratedObject.Insert("ObjectTypeDM", RelatedObjectsBefore[ObjectIS].ObjectTypeDM);
		EndIf;
		
		IntegratedObject.Insert("ListOfTSToBeUnloaded", PreliminaryData.ComplianceOfListOfTSToBeUnloadedWithIPObjects[ObjectIS]);
		IntegratedObject.Insert("ListOfExpressions", PreliminaryData.MatchingListOfExpressionsToIPObjects[ObjectIS]);
		IntegratedObject.Insert("VDOLoadingRule", VDOLoadingRule);
		IntegratedObject.Insert("FileFunctionalityIsAvailable", PreliminaryData.FileFunctionalityIsAvailable);
		IntegratedObject.Insert("PrintForms", New Array);
		IntegratedObject.Insert("TypesOfPrintedFormFiles", New Array);
		IntegratedObject.Insert("CreatingLinksIsAvailable", PreliminaryData.CreatingLinksIsAvailable);
		IntegratedObject.Insert("LinksToCreation", PreliminaryData.MatchingCreatedLinksToIPObjects[ObjectIS]);
		
		If PreliminaryData.FileFunctionalityIsAvailable Then
			IntegratedObject.PrintForms = PreliminaryData.ComplianceOfPrintedFormsWithIPObjects[ObjectIS];
			IntegratedObject.TypesOfPrintedFormFiles = PreliminaryData.TypesOfPrintedFormFiles[ObjectIS];
		EndIf;
		
		If TypeOf(ObjectsToDeleteFromChangeRegistration) = Type("Array") Then
			ObjectsToDeleteFromChangeRegistration.Add(ObjectIS);
		EndIf;
		
		DataArray.Add(IntegratedObject);
		
	EndDo;
	
	Return DataArray;
	
EndFunction

#EndRegion