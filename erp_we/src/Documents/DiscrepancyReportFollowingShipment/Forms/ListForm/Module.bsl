
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	CurCurrentTypeOfBasisOfAct = Undefined;
	Parameters.Property("TypeOfBaseDocumentForNonConformanceCertificate", CurCurrentTypeOfBasisOfAct);
	If Not ValueIsFilled(CurCurrentTypeOfBasisOfAct) Then
		Parameters.Filter.Property("TypeOfBaseDocumentForNonConformanceCertificate", CurCurrentTypeOfBasisOfAct);
	EndIf;
	
	If Not ValueIsFilled(CurCurrentTypeOfBasisOfAct) And ValueIsFilled(Parameters.CurrentRow) Then
		
		CurCurrentTypeOfBasisOfAct =
			Common.ObjectAttributeValue(Parameters.CurrentRow, "TypeOfBaseDocumentForNonConformanceCertificate");
		
		If CurCurrentTypeOfBasisOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider
		 Or CurCurrentTypeOfBasisOfAct = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider Then
			TypeOfBaseDocumentForNonConformanceCertificate = CurCurrentTypeOfBasisOfAct;
		EndIf;
		
	EndIf;
	DiscrepanciesServer.ReportOfDiscrepanciesListAndGroundsParameter(ThisObject, True);
	
	If ValueIsFilled(Parameters.FormCaption) Then
		Title = Parameters.FormCaption;
	EndIf;
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Manager", Manager, QuickFilterStructure);

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	
	TMCommonUse.CustomizePeripherals(ThisForm);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.ListOfTeamGroupGlobal);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	DiscrepanciesClient.ActOnDiscrepanciesListBeforeStartOfAddition(ThisObject, Item, Cancel, Copy, True);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	
EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
	
	If EventName = "Write_DiscrepancyReportFollowingShipment" Then
		// StandardSubsystems.AttachableCommands
		AttachableCommandsClient.StartCommandUpdate(ThisObject);
		// End StandardSubsystems.AttachableCommands
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Manager", Manager, QuickFilterStructure, Settings);
	
	DiscrepanciesClientServer.SetDynamicListStatusSelection(ThisForm.List, ThisForm.Status);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListOnChange(Item)
	ProvisionInDocumentsClient.CheckToRunBackgroundInventoryAllocationJob();
EndProcedure

#EndRegion

#Region FormHeaderEventHandlers

&AtClient
Procedure StatusFilterOnChange(Item)
	
	DiscrepanciesClientServer.SetDynamicListStatusSelection(ThisForm.List, ThisForm.Status);
	
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, 
	                                                                        "Manager",
	                                                                        Manager, 
	                                                                        DataCompositionComparisonType.Equal,
	                                                                        ,
	                                                                        ValueIsFilled(Manager));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands


// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure
// End StandardSubsystems.AttachableCommands


&AtClient
Procedure SetTheStatusNotAgreed(Command)
	
	SetStatus("NotApproved", NStr("vi = 'Không thống nhất';
									|ru = 'Не согласовано';
									|en = 'Not approved'; fa = 'تأییدنشده';
									|it = 'Non concordato';
									|pl = 'Nie uzgodniono';
									|tr = 'Beklemede'"));
	
EndProcedure

&AtClient
Procedure SetStatusSupplied(Command)
	
	SetStatus("Approved", NStr("vi = 'Được cung cấp';
								|ru = 'Обеспечивается';
								|en = 'Supplied'; fa = 'عرضه‌شده';
								|it = 'Viene approvvigionato';
								|pl = 'Supplied';
								|tr = 'Tarafından sağlanır'"));
	
EndProcedure

&AtClient
Procedure SetStatusProcessed(Command)
	
	SetStatus("Processed_", NStr("vi = 'Đã xử lý';
								|ru = 'Отработано';
								|en = 'Processed'; fa = 'پردازش‌شده';
								|it = 'Elaborato';
								|pl = 'Processed';
								|tr = 'İşlendi'"));
	
EndProcedure

&AtClient
Procedure SetStatusBeingProcessed(Command)
	
	SetStatus("ForCompletion", NStr("vi = 'Thực hiện';
									|ru = 'Отрабатывается';
									|en = 'Being processed'; fa = 'در حال پردازش';
									|it = 'Viene elaborato';
									|pl = 'Being processed';
									|tr = 'İşleniyor'"));
	
EndProcedure

&AtClient
Procedure SetStatus(StatusName, StatusPresentation)

	HighlightedLinks = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If HighlightedLinks.Count() = 0 Then
		Return;
	EndIf;
	
	ClearMessages();
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(HighlightedLinks, StatusName);
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, HighlightedLinks.Count(), StatusPresentation);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StatusFilter.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Status");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StatusesOfDiscrepancyReport.EmptyRef();
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	

	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);

	
EndProcedure

&AtClient
Function GetLinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.DiscrepancyReportFollowingShipment.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)

	If Not BarcodingOfItemsClient.BarcodesAreValid(Data) Then
		Return;
	EndIf;
	
	ReferencesArrray = GetLinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Items.List.CurrentRow = ReferencesArrray[0];
		ShowValue(Undefined, ReferencesArrray[0]);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands


&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.StatusPresentation Then
	EndIf;
	
EndProcedure

#EndRegion
