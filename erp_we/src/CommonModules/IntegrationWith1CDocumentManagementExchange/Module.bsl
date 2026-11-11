////////////////////////////////////////////////////////////////////////////////
// Subsystem "Integration with 1C:Document management"
// Module integration1sdocumentoobmain, server, external connection
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

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
//     * ObjectTypeDM - String
//     * ObjectIDDM - String
//     * FillingRule - CatalogRef.RulesForIntegrationWith1CDocumentManagement
//
Function RegisteredData(Proxy, ExchangeNode, ObjectsToDeleteFromChangeRegistration, EventName) Export
	
	SetPrivilegedMode(True);
	
	DataArray = New Array;
	
	Query = New Query(
		"SELECT
		|	Rules.Ref AS Rule
		|INTO TermsAndConditions
		|FROM
		|	Catalog.RulesForIntegrationWith1CDocumentManagement AS Rules
		|WHERE
		|	(CAST(Rules.ApplicabilityConditionOnExport AS STRING(1))) <> """"
		|
		|UNION
		|
		|SELECT
		|	ImportingRules.Ref
		|FROM
		|	Catalog.RulesForIntegrationWith1CDocumentManagement.AttributeFillingRulesIS AS ImportingRules
		|WHERE
		|	ImportingRules.KeyAttribute_
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Rules.Ref AS FillingRule,
		|	Rules.ObjectTypeIS AS ObjectTypeIS,
		|	Rules.ObjectTypeDM AS ObjectTypeDM,
		|	CASE
		|		WHEN Rules.Ref IN
		|				(SELECT
		|					TermsAndConditions.Rule
		|				FROM
		|					TermsAndConditions)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ThereAreConditions
		|INTO FillingRules
		|FROM
		|	Catalog.RulesForIntegrationWith1CDocumentManagement AS Rules
		|WHERE
		|	NOT Rules.Ref.DeletionMark
		|	AND Rules.ExportChanges");
	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Execute();
	
	// Let's check if we need to get related objects.
	IntegrationWith1CDocumentManagement.CheckUpdateRelatedObjectData();
	
	For Each ExchangePlanContentItem In ExchangeNode.Metadata().Content Do
		ChangeRequest = New Query;
		ChangeRequest.TempTablesManager = TempTablesManager;
		
		FullNameOfElementMetadata = ExchangePlanContentItem.Metadata.FullName();
		QueryText =
			"SELECT
			|	ChangesTable1.Ref AS Object,
			|	ISNULL(ObjectsIntegratedWith1CDocumentManagement.ObjectIDDM, """") AS ObjectIDDM,
			|	ISNULL(ObjectsIntegratedWith1CDocumentManagement.ObjectTypeDM, """") AS ObjectTypeDM,
			|	ISNULL(FillingRules.FillingRule, UNDEFINED) AS FillingRule,
			|	ISNULL(FillingRules.ThereAreConditions, UNDEFINED) AS ThereAreConditions
			|FROM
			|	&ChangesTable1 AS ChangesTable1
			|		LEFT JOIN InformationRegister.ObjectsIntegratedWith1CDocumentManagement AS ObjectsIntegratedWith1CDocumentManagement
			|			LEFT JOIN FillingRules AS FillingRules
			|			ON (FillingRules.ObjectTypeIS = &FullNameOfElementMetadata)
			|				AND ObjectsIntegratedWith1CDocumentManagement.ObjectTypeDM = FillingRules.ObjectTypeDM
			|		ON ChangesTable1.Ref = ObjectsIntegratedWith1CDocumentManagement.Object
			|WHERE
			|	ChangesTable1.Node = &Node
			|TOTALS
			|	MAX(ObjectIDDM),
			|	MAX(ObjectTypeDM)
			|BY
			|	Object";
		ChangeRequest.Text = StrReplace(
			QueryText,
			"&ChangesTable1",
			StrTemplate("%1.%2",
				FullNameOfElementMetadata,
				"Changes"));
		ChangeRequest.SetParameter("FullNameOfElementMetadata", FullNameOfElementMetadata);
		ChangeRequest.SetParameter("Node", ExchangeNode);
		SelectionOfObjects = ChangeRequest.Execute().Select(QueryResultIteration.ByGroups);
		
		While SelectionOfObjects.Next() Do
			
			If IntegrationWith1CDocumentManagementCore.ObjectDoesNotSupportExchange(SelectionOfObjects.ObjectTypeDM)
					And ValueIsFilled(SelectionOfObjects.ObjectIDDM) Then
				IntegratedObject = New Structure("Object", SelectionOfObjects.Object);
				IntegratedObject.Insert("ObjectTypeDM", SelectionOfObjects.ObjectTypeDM);
				IntegratedObject.Insert("ObjectIDDM", SelectionOfObjects.ObjectIDDM);
			Else
				// You don't need to upload an object.
				ObjectsToDeleteFromChangeRegistration.Add(SelectionOfObjects.Object);
				Continue;
			EndIf;
			
			RuleSelection_ = SelectionOfObjects.Select();
			RuleSelection_.Next();
			ThereAreAppropriateRules = (RuleSelection_.Count() = 1) And (RuleSelection_.ThereAreConditions = False);
			
			If ThereAreAppropriateRules Then
				IntegratedObject.Insert("FillingRule", RuleSelection_.FillingRule);
			Else
				// Clarification is required.
				Rules = IntegrationWith1CDocumentManagementServerCall.SuitableRules(SelectionOfObjects.Object);
				If Rules.Count() = 0 Then
					// The IP object will not be sent and will remain in the change registration table.
					ErrorText = StrTemplate(
						NStr("vi = 'Đối tượng ""%1"" (%2) đã được ghi nhận vào trao đổi dữ liệu với đối tượng liên kết trong 1C:Document Management,
							|nhưng không tìm thấy quy tắc tích hợp phù hợp.';
							|ru = 'Объект ""%1"" (%2) зарегистрирован к обмену данными со связанным объектом в 1С:Документооборот,
							|но подходящие правила интеграции не найдены.';
							|en = 'The ""%1"" (%2) object is registered to exchange data with the related object in 1C:Document Management.
							|However, no suitable integration rules are found.'; fa = 'The ""%1"" (%2) object is registered to exchange data with the related object in 1C:Document Management.
							|However, no suitable integration rules are found.';
							|it = 'Объект ""%1"" (%2) зарегистрирован к обмену данными со связанным объектом в 1С:Документооборот,
							|но подходящие правила интеграции не найдены.';
							|pl = 'The ""%1"" (%2) object is registered to exchange data with the related object in 1C:Document Management.
							|However, no suitable integration rules are found.';
							|tr = '""%1"" (%2) nesnesi 1C:Document Management ile ilişkili nesneyle veri değişimi için kaydedildi,
							|ancak uygun entegrasyon kuralı bulunamadı.'"),
						SelectionOfObjects.Object,
						TypeOf(SelectionOfObjects.Object));
					IntegrationWith1CDocumentManagementCore.WriteError(
						ErrorText,
						EventName,
						SelectionOfObjects.Object);
					Continue;
				EndIf;
				IntegratedObject.Insert("FillingRule", Rules[0].Ref);
			EndIf;
			
			DataArray.Add(IntegratedObject);
			ObjectsToDeleteFromChangeRegistration.Add(SelectionOfObjects.Object);
			
		EndDo;
		
	EndDo;
	
	TempTablesManager.Close();
	
	Return DataArray;
	
EndFunction

// Retrieves data from the Workflow.
//
Procedure GetData() Export
	
	Try
		
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		
		SkippingErrorMessagesIsSupported =
			IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("2.1.28.12.CORP");
		
		DocumentFlowNode = IntegrationWith1CDocumentManagementCoreCached.DocumentFlowNode();
		ExchangePlanContent = Metadata.ExchangePlans.IntegrationWith1CDocumentManagementSubsystemOverridable.Content;
		
		ReadAllMessages = False;
		LastMessageNumber = "";
		MessageWasAccepted = True;
		ErrorText = "";
		MissingMessages = New Array;
		
		While Not ReadAllMessages Do
			
			Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetChangesRequest");
			Query.lastMessageID = LastMessageNumber;
			
			If SkippingErrorMessagesIsSupported Then
				Query.lastMessageWasReceived = MessageWasAccepted;
				Query.errorDescription = ErrorText;
				
				If MessageWasAccepted = False
						And MissingMessages.Find(LastMessageNumber) = Undefined Then
					MissingMessages.Add(LastMessageNumber);
				EndIf;
				
				MissingMessagesInRequest = Query.skipMessages; // XDTOList
				For Each Item In MissingMessages Do
					MissingMessagesInRequest.Add(Item);
				EndDo;
			Else
				If MessageWasAccepted = False Then
					Break;
				EndIf;
			EndIf;
			
			Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
			IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
			
			LastMessageNumber = String(Response.messageID);
			MessageWasAccepted = True;
			ErrorText = "";
			
			For Each XDTODataObject In Response.objects Do
				
				If XDTODataObject.objectID.type = "DMInternalDocumentTemplate"
						Or XDTODataObject.objectID.type = "DMIncomingDocumentTemplate"
						Or XDTODataObject.objectID.type = "DMOutgoingDocumentTemplate" Then
					Catalogs.RulesForIntegrationWith1CDocumentManagement.UpdateRulesByTemplate(XDTODataObject);
					Continue;
				EndIf;
				
				References = IntegrationWith1CDocumentManagementCore.LinksToExternalObjects(XDTODataObject);
				
				For Each ObjectRef In References Do
					
					SuitableRules = IntegrationWith1CDocumentManagementServerCall.SuitableRules(
						ObjectRef,
						XDTODataObject);
					If SuitableRules = Undefined Or SuitableRules.Count() = 0 Then
						Continue;
					EndIf;
					Rule = SuitableRules[0].Ref;
					
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
					
					InformationRegisters.PreparationForUpdatingPrintedForms.Add(ObjectRef, Rule);
					
					Object = ObjectRef.GetObject();
					
					OriginalDeletionMark = Object.DeletionMark;
					
					RefreshEnabled = True;
					RequiresRecheck = False;
					HasChanges = Catalogs.RulesForIntegrationWith1CDocumentManagement.FillInObjectByXDTOObject(
						Proxy,
						Object,
						XDTODataObject,
						Rule,
						RefreshEnabled,
						RequiresRecheck);
					
					If HasChanges Then
						
						Try
							
							If Object.DeletionMark And Not OriginalDeletionMark Then
								
								ObjectMetadata = Object.Metadata();
								If Metadata.Documents.Contains(ObjectMetadata)
										And ObjectMetadata.Posting = Metadata.ObjectProperties.Posting.Allow
										And Object.Posted Then
									
									Action = NStr("vi = 'Xóa có hủy kết chuyển';
													|ru = 'Удаление с отменой проведения';
													|en = 'Delete and cancel posting'; fa = 'Delete and cancel posting';
													|it = 'Eliminazione con annullamento di pubblicazione';
													|pl = 'Usunięcie z zaznaczeniem zatwierdzenia';
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
								
							Else
								
								FilledInWasCorrectly = Object.CheckFilling();
								
								If FilledInWasCorrectly Then
									
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
									
								Else
									
									MessageWasAccepted = False;
									UserMessages = GetUserMessages(True);
									MessageText = New Array;
									MessageText.Add(
										StrTemplate(NStr("vi = 'Đối tượng: %1';
														|ru = 'Объект: %1';
														|en = 'Object: %1'; fa = 'Object: %1';
														|it = 'Oggetto: %1';
														|pl = 'Obiekt: %1';
														|tr = 'Nesne: %1'", Common.DefaultLanguageCode()),
											TrimAll(Object)));
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
									ErrorText = StrConcat(MessageText, Chars.LF);
									WriteLogEvent(
										IntegrationWith1CDocumentManagementCore.EventLogEventName(
											NStr("vi = 'Nhận dữ liệu';
												|ru = 'Получение данных';
												|en = 'Get data'; fa = 'Get data';
												|it = 'Acquisizione dei dati';
												|pl = 'Pobieranie danych';
												|tr = 'Veri alımı'", Common.DefaultLanguageCode())),
										EventLogLevel.Error,,
										"DMGetChangesRequest",
										ErrorText);
									Break;
									
								EndIf;
								
							EndIf;
							
						Except
							MessageWasAccepted = False;
							ErrorText = StrTemplate(NStr("vi = 'Thao tác: %1
														|%2';
														|ru = 'Действие: %1
														|%2';
														|en = 'Action: %1
														|%2'; fa = 'Action: %1
														|%2';
														|it = 'Azione: %1
														|%2';
														|pl = 'Czynność: %1
														|%2';
														|tr = 'Eylem: %1
														|%2'", Common.DefaultLanguageCode()),
								Action,
								ErrorProcessing.DetailErrorDescription(ErrorInfo()));
							WriteLogEvent(
								IntegrationWith1CDocumentManagementCore.EventLogEventName(
									NStr("vi = 'Nhận dữ liệu';
										|ru = 'Получение данных';
										|en = 'Get data'; fa = 'Get data';
										|it = 'Acquisizione dei dati';
										|pl = 'Pobieranie danych';
										|tr = 'Veri alımı'", Common.DefaultLanguageCode())),
								EventLogLevel.Error,,
								"DMGetChangesRequest",
								ErrorText);
							Break;
						EndTry;
						
						If ExchangePlanContent.Contains(Object.Metadata()) Then
							ExchangePlans.DeleteChangeRecords(DocumentFlowNode, Object.Ref);
						EndIf;
						
					EndIf;
					
				EndDo;
				
				If MessageWasAccepted = False Then
					Break;
				EndIf;
				
			EndDo;
			
			// Since version 1.4.8, the states of agreement on the IC side are being updated.
			If MessageWasAccepted And Response.Properties().Get("records") <> Undefined Then
				
				For Each XDTODataObject In Response.records Do
					
					RelatedObjectRequest = New Query(
						"SELECT TOP 1
						|	Object
						|FROM
						|	InformationRegister.ObjectsIntegratedWith1CDocumentManagement
						|WHERE
						|	ObjectTypeDM = &ObjectTypeDM
						|	AND ObjectIDDM = &ObjectIDDM");
					If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, XDTODataObject, "DMApprovalStateRecord") Then
						RelatedObjectRequest.SetParameter("ObjectTypeDM", XDTODataObject.type);
						RelatedObjectRequest.SetParameter("ObjectIDDM", XDTODataObject.ID);
						Selection = RelatedObjectRequest.Execute().Select();
						If Selection.Next() Then
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
									StateID = XDTODataObject.status.objectID.ID;
									State = Enums.ApprovalStatesIn1CDocumentManagement[StateID];
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
								MessageWasAccepted = False;
								ErrorText = StrTemplate(NStr("vi = 'Thao tác: %1
															|%2';
															|ru = 'Действие: %1
															|%2';
															|en = 'Action: %1
															|%2'; fa = 'Action: %1
															|%2';
															|it = 'Azione: %1
															|%2';
															|pl = 'Czynność: %1
															|%2';
															|tr = 'Eylem: %1
															|%2'", Common.DefaultLanguageCode()),
									Action,
									ErrorProcessing.DetailErrorDescription(ErrorInfo()));
								WriteLogEvent(
									IntegrationWith1CDocumentManagementCore.EventLogEventName(
										NStr("vi = 'Nhận dữ liệu';
											|ru = 'Получение данных';
											|en = 'Get data'; fa = 'Get data';
											|it = 'Acquisizione dei dati';
											|pl = 'Pobieranie danych';
											|tr = 'Veri alımı'", Common.DefaultLanguageCode())),
									EventLogLevel.Error,,
									"DMGetChangesRequest",
									ErrorText);
								Break;
							EndTry;
						EndIf;
					EndIf;
					
				EndDo;
				
			EndIf;
			
			ReadAllMessages = (Response.messageID = Undefined);
			
		EndDo;
		
	Except
		WriteLogEvent(
			IntegrationWith1CDocumentManagementCore.EventLogEventName(
				NStr("vi = 'Nhận dữ liệu';
					|ru = 'Получение данных';
					|en = 'Get data'; fa = 'Get data';
					|it = 'Acquisizione dei dati';
					|pl = 'Pobieranie danych';
					|tr = 'Veri alımı'",
					Common.DefaultLanguageCode())),
			EventLogLevel.Error,,
			"DMGetChangesRequest",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

// Returns an XDTO object containing the updated changes to the object.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   ObjectData - See IntegrationWith1CDocumentManagementExchange.RegisteredData
//   ControlOverSendingFiles - See IntegrationWith1CDocumentManagementCore.ControlOverSendingFiles
//
// Returns:
//   XDTODataObject
//
Function GetXDTOOfChangesFromObject(Proxy, ObjectData, ControlOverSendingFiles) Export
	
	If IntegrationWith1CDocumentManagementClientServer.IsDocument(ObjectData.ObjectTypeDM) Then
		
		// we will receive a document with the Cur signatures filled in.
		// The web service BEFORE 2.1 cannot unambiguously determine whether the signatures were purposefully deleted or
		// the list of signatures simply was not filled in.
		Try
			XDTODataObject = IntegrationWith1CDocumentManagementCore.GetObject(
				Proxy,
				ObjectData.ObjectTypeDM,
				ObjectData.ObjectIDDM,
				"documentType,signatures");
		Except
			XDTODataObject = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				ObjectData.ObjectTypeDM);
		EndTry;
		
	Else
		
		XDTODataObject = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			ObjectData.ObjectTypeDM);
		
	EndIf;
	
	ListOfFiles = XDTODataObject.files; // XDTOList
	
	XDTODataObject.name = String(ObjectData.Object);
	
	XDTODataObject.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		ObjectData.ObjectIDDM,
		ObjectData.ObjectTypeDM);
	
	AttributesStructure1 = IntegrationWith1CDocumentManagement.StructureOfTheAttributesOfTheFilledObjectDM(
		ObjectData.ObjectTypeDM);
	
	DoNotUpdateAccordingToRules = New Array;
	Catalogs.RulesForIntegrationWith1CDocumentManagement.FillInMapItemDetailsStructureUsingRule(
		ObjectData.Object,
		AttributesStructure1,
		ObjectData.FillingRule,
		ControlOverSendingFiles,
		True,
		DoNotUpdateAccordingToRules);
	
	MatchingBankDetails =
		Catalogs.RulesForIntegrationWith1CDocumentManagement.MatchingXDTPropertiesAndObjectFormDetailsTo(
			ObjectData.ObjectTypeDM);
	
	For Each MapRow In MatchingBankDetails Do
		If DoNotUpdateAccordingToRules.Find(MapRow.Key) <> Undefined Then
			Continue;
		EndIf;
		IntegrationWith1CDocumentManagement.FillInXDTPropertyOfOizPropsStructure(
			Proxy,
			XDTODataObject,
			MapRow.Key,
			AttributesStructure1,
			MapRow.Value);
	EndDo;
	
	DataProcessors.IntegrationWith1CDocumentManagementCore.GenerateAdditionalProperties(
		Proxy,
		XDTODataObject,
		AttributesStructure1);
	
	If AttributesStructure1.Property("Files") And AttributesStructure1.Files.Count() > 0 Then
		
		For Each CreationParameters In AttributesStructure1.Files Do
			XDTOFile = IntegrationWith1CDocumentManagementCore.XDTOFileFromCreationParameters(
				Proxy,
				CreationParameters);
			ListOfFiles.Add(XDTOFile);
		EndDo;
		
	EndIf;
	
	XDTODataObject.externalObject = IntegrationWith1CDocumentManagementCore.CreateExternalObject(
		Proxy,
		ObjectData.Object);
	
	Return XDTODataObject;
	
EndFunction

#EndRegion