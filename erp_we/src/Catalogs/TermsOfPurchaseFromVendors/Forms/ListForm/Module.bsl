
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	List.Parameters.SetParameterValue("UpdateDate", BegOfDay(CurrentSessionDate()));
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	ListSelectionsClientServer.FillInSelectionSelectionListByRelevance(Items.FilterValidityPeriod.ChoiceList);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Manager", Manager, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByRelevanceWhenCreatingOnServer(List, Relevance, Items.FilterValidityPeriod.ChoiceList, EventDate, QuickFilterStructure);

	If ListSelectionsClientServer.YouNeedToSelectByStateWhenCreatingOnServer(State, QuickFilterStructure) Then
		CommonClientServer.SetDynamicListFilterItem(List, "State", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
	EndIf;
	
	If Parameters.Filter.Property("Partner") Then
		Title = NStr("vi = 'Thỏa thuận với nhà cung cấp';
					|ru = 'Соглашения с поставщиком';
					|en = 'Terms of purchase'; fa = 'شرایط خرید';
					|it = 'Accordi con il fornitore';
					|pl = 'Porozumienia z dostawcą';
					|tr = 'Satın alma koşulları'");
	EndIf;
	
	Items.SetStatusValid.Visible = AccessRight("Update", Metadata.Catalogs.TermsOfPurchaseFromVendors);
	Items.SetTheStatusNotAgreed.Visible = AccessRight("Update", Metadata.Catalogs.TermsOfPurchaseFromVendors);
	Items.SetClosedStatus.Visible = AccessRight("Update", Metadata.Catalogs.TermsOfPurchaseFromVendors);
	
	Parameters.Property("AgencyServiceProducts", AgencyServiceProducts);
	Parameters.Property("AgencyServiceCharacteristic", AgencyServiceCharacteristic);
	
	If Not ValueIsFilled(AgencyServiceProducts) Then
		Items.FilterAgentService.Visible = False;
		Items.AddServiceToAgreement.Visible = False;
	Else
		
		Items.FilterAgentService.ChoiceList[0].Presentation =
					ProductsClientServer.ProductPresentation(AgencyServiceProducts, AgencyServiceCharacteristic);
					
		If Parameters.EnableAgencyServiceSelection Then
			FilterAgentService = "ForProductsOnly";
		EndIf;
		
		Items.AddServiceToAgreement.Visible = AccessRight("Update", Metadata.Catalogs.TermsOfPurchaseFromVendors);
						
		SetSelectionByAgencyService();
		
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If ValueIsFilled(UpdateDate) Then
		List.Parameters.SetParameterValue("UpdateDate", UpdateDate);
	EndIf;
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Manager", Manager, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByRelevanceWhenLoadingFromSettings(List, Relevance, Items.FilterValidityPeriod.ChoiceList, EventDate, QuickFilterStructure, Settings);
	
	If ListSelectionsClientServer.YouNeedToSelectByStateWhenLoadingFromSettings(State, QuickFilterStructure, Settings) Then
		CommonClientServer.SetDynamicListFilterItem(List, "State", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterStateOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "State", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
	
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Manager", Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));
	
EndProcedure

&AtClient
Procedure FilterValidityPeriodOnChange(Item)
	
	ListSelectionsClientServer.WhenChangingRelevanceSelection(List, Relevance, EventDate, Items.FilterValidityPeriod.ChoiceList);
	
EndProcedure

&AtClient
Procedure FilterValidityPeriodClearing(Item, StandardProcessing)
	
	ListSelectionsClientServer.WhenClearingSelectionByRelevance(List, Relevance, EventDate, StandardProcessing);
	
EndProcedure

&AtClient
Procedure FilterValidityPeriodChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	TMCommonUseClient.WhenSelectingRelevanceSelection(
		ValueSelected, 
		StandardProcessing, 
		ThisForm,
		List, 
		"Relevance",
		"FilterValidityPeriod",
		"EventDate");
	
EndProcedure

&AtClient
Procedure ProductsOnChange(Item)
	SetSelectionByAgencyService();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetTheStatusNotAgreed (Command)
	
	If Not TMCommonUseClient.CheckForSelectedLinesInList(Items.List) Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Ở những thỏa thuận đã chọn trong danh sách thiết lập trạng thái ""Chưa điều chỉnh"". Theo thỏa thuận hiện hành có thể lập chứng từ. Sau khi thay đổi trạng thái thì thỏa thuận hiện hành không còn hiệu lực. Tiếp tục?';
					|ru = 'У выделенных в списке соглашений будет установлен статус ""Не согласовано"". По действующим соглашениям могут быть оформлены документы. После изменения статуса действующие соглашения перестанут действовать. Продолжить?';
					|en = 'Status of the agreements selected in the list will be set to Not approved. Documents can be generated for valid agreements. Once the status is changed, the agreements will be no longer valid. Continue?'; fa = 'Status of the agreements selected in the list will be set to Not approved. Documents can be generated for valid agreements. Once the status is changed, the agreements will be no longer valid. Continue?';
					|it = 'Gli accordi selezionati nell''elenco saranno impostati su ""Non concordato"". Secondo gli accordi esistenti potranno essere stilati dei documenti. Dopo la modifica dello stato, gli accordi esistenti cesseranno di funzionare. Continuare?';
					|pl = 'Dla porozumień zaznaczonych na liście zostanie ustawiony status ""Nieuzgodnione"". Dla aktualnych porozumień mogą być sporządzone dokumenty. Po zmianie statusu aktualne porozumienia utracą ważność. Kontynuować?';
					|tr = 'Listede seçili anlaşmaların durumu ""Kabul edilmedi"" olarak ayarlanacaktır. Mevcut anlaşmalar için belge düzenlenebilir. Durum değiştirildikten sonra, mevcut anlaşmaların geçerliliği sona erecektir. Devam edilsin mi?'");
	Response = Undefined;
	
	ShowQueryBox(New CallbackDescription("SetTheStatusNotAgreedCompletion", ThisObject), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheStatusNotAgreedCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ClearMessages();
	
	ProcessedItemsCount = SetTheStatusNotAgreedServer(Items.List.SelectedRows);
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, Items.List.SelectedRows.Count(), NStr("vi = 'Không thống nhất';
																															|ru = 'Не согласовано';
																															|en = 'Not approved'; fa = 'تأییدنشده';
																															|it = 'Non concordato';
																															|pl = 'Nie uzgodniono';
																															|tr = 'Beklemede'"));

EndProcedure

&AtClient
Procedure SetStatusValid (Command)
	
	If Not TMCommonUseClient.CheckForSelectedLinesInList(Items.List) Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Ở những thỏa thuận đã chọn trong danh sách sẽ đặt trạng thái ""Hiệu lực"". Tiếp tục?';
					|ru = 'У выделенных в списке соглашений будет установлен статус ""Действует"". Продолжить?';
					|en = 'Status of the agreements selected in the list will be set to Valid. Continue?'; fa = 'Status of the agreements selected in the list will be set to Valid. Continue?';
					|it = 'Agli accordi selezionati nell''elenco verrà assegnato lo stato ""Attivo"". Continuare?';
					|pl = 'Dla porozumień zaznaczonych na liście zostanie ustawiony status ""Aktualne"". Kontynuować?';
					|tr = 'Listede seçili anlaşmaların durumu ""Aktif"" olarak ayarlanacaktır. Devam edilsin mi?'");
	Response = Undefined;
	
	ShowQueryBox(New CallbackDescription("SetStatusValidCompletion", ThisObject), QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetStatusValidCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ClearMessages();
	
	ProcessedItemsCount = SetStatusValidServer(Items.List.SelectedRows);
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, Items.List.SelectedRows.Count(), NStr("vi = 'Có hiệu lực';
																															|ru = 'Действует';
																															|en = 'Valid'; fa = 'معتبر';
																															|it = 'In vigore';
																															|pl = 'Valid';
																															|tr = 'Aktif'"));
	
EndProcedure

&AtClient
Procedure SetClosedStatus (Command)
	
	If Not TMCommonUseClient.CheckForSelectedLinesInList(Items.List) Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Ở thỏa thuận đã chọn trong danh sách sẽ đặt trạng thái ""Đóng"". Sau khi thay đổi trạng thái thì thỏa thuận có hiệu lực sẽ không còn hiệu lực. Tiếp tục?';
					|ru = 'У выделенных в списке соглашений будет установлен статус ""Закрыто"". После изменения статуса действующие соглашения перестанут действовать. Продолжить?';
					|en = 'Status of the agreements selected in the list will be set to Closed. Once the status is changed, the agreements will be no longer valid. Continue?'; fa = 'Status of the agreements selected in the list will be set to Closed. Once the status is changed, the agreements will be no longer valid. Continue?';
					|it = 'Agli accordi selezionati nell''elenco verrà assegnato lo stato ""Chiuso"". Dopo la modifica dello stato gli accordi attivi smetteranno di funzionare. Procedere?';
					|pl = 'Dla porozumień zaznaczonych na liście zostanie ustawiony status ""Zamknięte"". Po zmianie statusu aktualne porozumienia utracą ważność. Kontynuować?';
					|tr = 'Listede seçili anlaşmaların durumu ""Kapalı"" olarak ayarlanacaktır. Durum değiştirildikten sonra, mevcut anlaşmaların geçerliliği sona erecektir. Devam edilsin mi?'");
	Response = Undefined;
	
	ShowQueryBox(New CallbackDescription("SetClosedStatusCompletion", ThisObject), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetClosedStatusCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ClearMessages();

	ProcessedItemsCount = SetClosedStatusServer(Items.List.SelectedRows);
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, Items.List.SelectedRows.Count(), NStr("vi = 'Đã đóng';
																															|ru = 'Закрыто';
																															|en = 'Closed'; fa = 'بسته‌شده';
																															|it = 'Chiuso';
																															|pl = 'Closed';
																															|tr = 'Kapalı'"));

EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure AddServiceToAgreement(Command)
	
	ClearMessages();
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then
		MessageText = NStr("vi = 'Chọn thỏa thuận';
							|ru = 'Выберите соглашение';
							|en = 'Select an agreement'; fa = 'Select an agreement';
							|it = 'Selezionate un accordo';
							|pl = 'Wybierz porozumienie';
							|tr = 'Anlaşma seçiniz'");
		ShowMessageBox(,MessageText);
		Return;
	EndIf;
	
	If Not CurrentData.UseSpecifiedAgentServices Then
		MessageText = NStr("vi = 'Thỏa thuận được chọn là hợp lệ cho tất cả các dịch vụ. Thêm một dịch vụ là không cần thiết.';
							|ru = 'Выбранное соглашение действует для всех услуг. Добавлять услугу не требуется.';
							|en = 'The selected agreement is valid for all services. You do not need to add a service.'; fa = 'The selected agreement is valid for all services. You do not need to add a service.';
							|it = 'L''accordo selezionato è valido per tutti i servizi. Non è necessario aggiungere il servizio.';
							|pl = 'Wybrana umowa jest ważna dla wszystkich usług, Dodawanie usługi nie jest wymagane.';
							|tr = 'Seçilen anlaşma tüm hizmetler için geçerlidir. Bir hizmet eklemenize gerek yoktur.'");
		ShowMessageBox(,MessageText);
		Return;
	EndIf;
	
	If ServiceAgreements.Find(CurrentData.Ref) <> Undefined Then
		MessageText = NStr("vi = 'Thỏa thuận đã chọn đã chỉ ra dịch vụ này.';
							|ru = 'В выбранном соглашении уже указана данная услуга.';
							|en = 'This service is already specified in the selected agreement.'; fa = 'This service is already specified in the selected agreement.';
							|it = 'Questo servizio è già elencato nell''accordo selezionato.';
							|pl = 'W wybranym porozumieniu wskazano już daną usługę.';
							|tr = 'Seçilen anlaşma bu hizmeti zaten belirtmektedir.'");
		ShowMessageBox(,MessageText);
		Return;
	EndIf;	
	
	Written1 = AddServiceToAgreementServer(CurrentData.Ref, AgencyServiceProducts, AgencyServiceCharacteristic);
	
	If Written1 Then
		TMCommonUseClient.NotifyUserAboutChangesToObject(CurrentData.Ref, NStr("vi = 'Dịch vụ này đã được thêm vào thỏa thuận.';
																				|ru = 'Услуга добавлена в соглашение.';
																				|en = 'Service is added to the agreement.'; fa = 'Service is added to the agreement.';
																				|it = 'Servizio aggiunto all''accordo.';
																				|pl = 'Usługa została dodana do porozumienia.';
																				|tr = 'Söz konusu hizmet anlaşmaya eklenmiştir.'"));
		Notify("Write_TermsOfPurchaseFromVendors",,CurrentData.Ref);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetSelectionByAgencyService()
	
	If ServiceAgreements = Undefined Then
		Query = New Query;
		Query.Text =
		"SELECT DISTINCT
		|	TermsOfPurchaseFromVendorsAgentServices.Ref AS Ref
		|FROM
		|	Catalog.TermsOfPurchaseFromVendors.AgentServices AS TermsOfPurchaseFromVendorsAgentServices
		|WHERE
		|	TermsOfPurchaseFromVendorsAgentServices.Products = &Products
		|	AND TermsOfPurchaseFromVendorsAgentServices.Characteristic = &Characteristic
		|
		|UNION ALL
		|
		|SELECT
		|	TermsOfPurchaseFromVendors.Ref
		|FROM
		|	Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchaseFromVendors
		|WHERE
		|	NOT TermsOfPurchaseFromVendors.UseSpecifiedAgentServices
		|	AND TermsOfPurchaseFromVendors.BusinessOperation = VALUE(Enum.BusinessTransactions.AgentServicesDelivery)";
		
		Query.SetParameter("Products", AgencyServiceProducts);
		Query.SetParameter("Characteristic", AgencyServiceCharacteristic);
		
		ServiceAgreements = New FixedArray(Query.Execute().Unload().UnloadColumn("Ref"));
	EndIf;
	
	If FilterAgentService = "ForProductsOnly" Then
		ListOfAgreements_ = New ValueList;
		ListOfAgreements_.LoadValues(New Array(ServiceAgreements));
		CommonClientServer.SetDynamicListFilterItem(List,
																			"Ref",
																			ListOfAgreements_,
																			DataCompositionComparisonType.InList,
																			,
																			True);
	Else
		CommonClientServer.SetDynamicListFilterItem(List, "Ref",,,,False);
	EndIf;
EndProcedure

&AtServerNoContext
Function SetTheStatusNotAgreedServer (Val Terms1)
	
	Return Catalogs.TermsOfPurchaseFromVendors.SetStatus(Terms1, Enums.StatusesOfTermsOfPurchase.NotApproved);
	
EndFunction

&AtServerNoContext
Function SetStatusValidServer (Val Terms1)
	
	Return Catalogs.TermsOfPurchaseFromVendors.SetStatus(Terms1, Enums.StatusesOfTermsOfPurchase.Valid);
	
EndFunction

&AtServerNoContext
Function SetClosedStatusServer (Val Terms1)
	
	Return Catalogs.TermsOfPurchaseFromVendors.SetStatus(Terms1, Enums.StatusesOfTermsOfPurchase.Closed);
	
EndFunction

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure

// Parameters:
// 	Terms - CatalogRef.TermsOfPurchaseFromVendors - 
// 	Products - CatalogRef.Products - 
// 	Characteristic - CatalogRef.ItemsCharacteristics - 
// 	
// Returns:
// 	Boolean - Service added
// 
&AtServerNoContext
Function AddServiceToAgreementServer(Terms, Products, Characteristic)
	
	ServiceAdded = True;
	
	Try
		LockDataForEdit(Terms);
	Except
		
		ErrorText = NStr("vi = 'Không thể phong tỏa %Terms%. %ErrorDescription%';
						|ru = 'Не удалось заблокировать %Terms%. %ErrorDescription%';
						|en = 'Failed to lock %Terms%. %ErrorDescription%'; fa = 'Failed to lock %Terms%. %ErrorDescription%';
						|it = 'Non è stato possibile bloccare %Terms%. %ErrorDescription%';
						|pl = 'Nie udało się zablokować %Terms%. %ErrorDescription%';
						|tr = '%Terms% bloke edilemedi. %ErrorDescription%'");
		ErrorText = StrReplace(ErrorText, "%Terms%",Terms);
		ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
		CommonClientServer.MessageToUser(ErrorText, Terms);
		
		ServiceAdded = False;
	EndTry;
	
	If ServiceAdded Then 
		
		AgreementObject = Terms.GetObject();
		NewRow = AgreementObject.AgentServices.Add();
		NewRow.Products = Products;
		NewRow.Characteristic = Characteristic;
		
		ErrorsFoundDuringVerification = False; 
		AgreementObject.CheckAgencyServices(ErrorsFoundDuringVerification);
		If ErrorsFoundDuringVerification Then
			ServiceAdded = False;
		Else	
			Try
				AgreementObject.Write();
			Except
				ErrorText = NStr("vi = 'Không thể ghi lại %Terms%. %ErrorDescription%';
								|ru = 'Не удалось записать %Terms%. %ErrorDescription%';
								|en = 'Failed to save %Terms%. %ErrorDescription%'; fa = 'Failed to save %Terms%. %ErrorDescription%';
								|it = 'Non è stato possibile scrivere %Terms%. %ErrorDescription%';
								|pl = 'Nie udało się zapisać %Terms%. %ErrorDescription%';
								|tr = '%Terms% Kaydedilemedi. %ErrorDescription%'");
				ErrorText = StrReplace(ErrorText, "%Terms%", Terms);
				ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
				CommonClientServer.MessageToUser(ErrorText, Terms);
				ServiceAdded = False;
			EndTry;
		EndIf;
		
	EndIf;
	
	Return ServiceAdded;
EndFunction

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "Write_TermsOfPurchaseFromVendors" Then
		If ValueIsFilled(AgencyServiceProducts) Then
			ServiceAgreements = Undefined;
			SetSelectionByAgencyService();
		EndIf;
	EndIf;
EndProcedure

#EndRegion
