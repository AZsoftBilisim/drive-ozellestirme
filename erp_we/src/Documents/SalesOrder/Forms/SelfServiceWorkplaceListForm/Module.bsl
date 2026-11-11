
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
		
	FillPropertyValues(ThisObject, PartnersAndCounterpartiesServerCall.DataOfAuthorizedExternalUser());
		
	If Partner = Undefined Or Partner.IsEmpty() Then
		 Cancel = True;
		 Return;
	EndIf;
	
	SelfServiceServer.ListFormOnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	SelfServiceServer.FillInContactPersonSelectionList(Items.ContactPersonFilter.ChoiceList, Partner, ContactPerson);
	SetItemsVisibility();
	
	CommonClientServer.SetDynamicListParameter(List, "UpdateDate", BegOfDay(CurrentSessionDate()));
	CommonClientServer.SetDynamicListParameter(List, "Partner", Partner);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ContactPersonFilter  = Settings.Get("ContactPersonFilter");
	SelfServiceClientServer.SetListSelectionByContactPerson(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure NotShowClosedOnChange(Item)
	
	If NotShowClosed Then
		CommonClientServer.SetDynamicListFilterItem(List,
		                                                                        "State", 
		                                                                        PredefinedValue("Enum.SalesOrderStates.Closed"), 
		                                                                        DataCompositionComparisonType.NotEqual,
		                                                                        ,
		                                                                        True);
	Else
		CommonClientServer.DeleteDynamicListFilterGroupItems(List, "State");
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.Posted
		And (Not CurrentData.AvailableToExternalUsers
		Or CurrentData.Status <> PredefinedValue("Enum.SalesOrderStatuses.NotApproved")) Then
		
		Cancel = True;
		Print();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ContactPersonFilterOnChange(Item)
	
	SelfServiceClientServer.SetListSelectionByContactPerson(ThisObject);
	
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

#Region Private

&AtClient
Procedure Print()

	ReferencesArrray = New Array;
	For Each Ref In Items.List.SelectedRows Do
		ReferencesArrray.Add(Ref);
	EndDo;
	
	SelfServiceClient.PrintOrderDocument(ReferencesArrray);
	
EndProcedure

&AtServer
Procedure SetItemsVisibility()
	
	UseAdvancedFeaturesOfSalesOrder = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	
	Items.ListPayAmount.Visible     = UseAdvancedFeaturesOfSalesOrder;
	Items.ListCustomerAccountsReceivable.Visible   = UseAdvancedFeaturesOfSalesOrder;
	Items.ListState.Visible       = UseAdvancedFeaturesOfSalesOrder;
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	ClearMessages();
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
// End StandardSubsystems.AttachableCommands

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Changing the status view, if the order is not carried out
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Thay đổi trình bày trạng thái, nếu chưa kết chuyển chứng từ.';
							|ru = 'Изменение представления состояния, если документ не проведен.';
							|en = 'Change state presentation if the document is not posted.'; fa = 'Change state presentation if the document is not posted.';
							|it = 'Modifica della visualizzazione di stato se il documento non è stato registrato.';
							|pl = 'Zmiana prezentacji statusu, jeżeli dokument nie jest zatwierdzony.';
							|tr = 'Belge kaydedilmemişse durum görünümünün değiştirilmesi'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListState.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Posted");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Bản nháp';
													|ru = 'Черновик';
													|en = 'Draft'; fa = 'پیش‌نویس';
													|it = 'Bozza';
													|pl = 'Draft';
													|tr = 'Taslak'"));
	
	// Changing the color of the status, if the processing of the order is overdue
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Màu nội dung của dòng, nếu chứng từ đơn hàng đã quá hạn chưa kết chuyển.';
							|ru = 'Цвет текста строки, если документ заказ просрочен не проведен.';
							|en = 'Text line color if document order is overdue not posted.'; fa = 'Text line color if document order is overdue not posted.';
							|it = 'Il colore del testo della riga se il documento dell''ordine è scaduto o non è registrato.';
							|pl = 'Kolor tekstu wiersza, jeżeli dokument zamówienie jest zaległy nie zatwierdzony.';
							|tr = 'Sipariş belgesinin süresi geçmişse satır metni renklendirilmez.'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListState.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Overdue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDocument);
	
	// Changing the color of the status, if the order is closed
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Màu nội dung của dòng, nếu chứng từ đơn hàng đã quá hạn chưa kết chuyển.';
							|ru = 'Цвет текста строки, если документ заказ просрочен не проведен.';
							|en = 'Text line color if document order is overdue not posted.'; fa = 'Text line color if document order is overdue not posted.';
							|it = 'Il colore del testo della riga se il documento dell''ordine è scaduto o non è registrato.';
							|pl = 'Kolor tekstu wiersza, jeżeli dokument zamówienie jest zaległy nie zatwierdzony.';
							|tr = 'Sipariş belgesinin süresi geçmişse satır metni renklendirilmez.'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListState.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.State");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SalesOrderStates.Closed;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);
	

	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.ListDate.Name);

	
EndProcedure

#EndRegion
