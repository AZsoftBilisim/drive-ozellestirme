

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Items.PurchaseAdjustmentListCreateBasedOnThePurchaseOfGoodsServices.Visible =
		AccessRight("Insert", Metadata.Documents.PurchaseAdjustment)
		And AccessRight("Update", Metadata.Documents.VendorInvoice);
	Items.PurchaseAdjustmentListGenerateFromPurchaseOfServicesAndOtherAssets.Visible =
		AccessRight("Insert", Metadata.Documents.PurchaseAdjustment)
		And AccessRight("Update", Metadata.Documents.VendorInvoiceServicesAndAssets);
	Items.PurchaseAdjustmentListCreateBasedOnPurchaseBeforeEnteringBalance.Visible =
		AccessRight("Insert", Metadata.Documents.PurchaseAdjustment)
		And AccessRight("Update", Metadata.Documents.SourceDocument)
		And GetFunctionalOption("NewOnlineARAPAccounting");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.PurchaseAdjustmentListGroupGlobalCommands);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "PurchaseAdjustmentList.Date", Items.PurchaseAdjustmentListDate.Name);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	If GetFunctionalOption("UseProductionByThirdParty2_5")
		And AccessRight("Insert", Metadata.Documents.PurchaseAdjustment)
		And AccessRight("Update", Metadata.Documents.SubcontractorReport2_5) Then
		
		NewCommand = Commands.Add("CreateBasedOnProcessorReport");
		NewCommand.Title = NStr("vi = 'Điều chỉnh bảng kê của bên nhận gia công';
								|ru = 'Корректировка отчета переработчика';
								|en = 'Adjust subcontracting services notification received'; fa = 'Adjust subcontracting services notification received';
								|it = 'Rettifica report elaboratore';
								|pl = 'Korekta raportu przetwórcy';
								|tr = 'Fason üretici raporunun düzenlenmesi'");
		NewCommand.Action = "CreateBasedOnProcessorReport";
	
		NewItem = Items.Add("CreateListOfNewAcquisitionsBasedOnProcessorSReport", Type("FormButton"),
			Items.PurchaseAdjustmentListGroupCreate);
		
		NewItem.Type    = FormButtonType.CommandBarButton; // button type
		NewItem.CommandName = "CreateBasedOnProcessorReport";
	EndIf;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	Manager = Settings.Get("Manager");
	
	CommonClientServer.SetDynamicListFilterItem(PurchaseAdjustmentList, "Manager", Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ManagerOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(PurchaseAdjustmentList, "Manager", Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPurchaseAdjustmentList

&AtClient
Procedure PurchaseAdjustmentListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure PurchaseAdjustmentListOnChange(Item)
	ProvisionInDocumentsClient.CheckToRunBackgroundInventoryAllocationJob();
EndProcedure

&AtServerNoContext
Procedure PurchaseAdjustmentListOnGetDataAtServer(TagName, Settings, Rows)
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.PurchaseAdjustmentList);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.PurchaseAdjustmentList, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.PurchaseAdjustmentList);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.PurchaseAdjustmentList);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure


&AtClient
Procedure PurchaseAdjustmentListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.ListOfPurchaseAdjustmentsEdVersionStatus Then
	EndIf;
	
EndProcedure


&AtClient
Procedure CreateBasedOnThePurchaseOfGoodsServices(Command)
	
	OpenForm("Document.PurchaseAdjustment.ObjectForm",
		New Structure("Basis", PredefinedValue("Document.VendorInvoice.EmptyRef")));
	
EndProcedure

&AtClient
Procedure GenerateFromPurchaseOfServicesAndOtherAssets(Command)
	
	OpenForm("Document.PurchaseAdjustment.ObjectForm",
		New Structure("Basis", PredefinedValue("Document.VendorInvoiceServicesAndAssets.EmptyRef")));
	
EndProcedure

&AtClient
Procedure CreateBasedOnPurchaseBeforeEnteringBalance(Command)
	
	FillingValues = New Structure();
	FillingValues.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.AdjustBeforeEnteringBalance"));
	
	OpenForm("Document.PurchaseAdjustment.ObjectForm",
		New Structure("FillingValues", FillingValues));
	
EndProcedure
&AtClient
Procedure CreateBasedOnProcessorReport(Command)
	
	OpenForm("Document.PurchaseAdjustment.ObjectForm",
		New Structure("Basis", PredefinedValue("Document.SubcontractorReport2_5.EmptyRef")));
	
EndProcedure

#EndRegion
