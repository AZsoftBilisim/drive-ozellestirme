
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Items.ListSaleAdjustmentsCreateOnBasisOfGoodsServicesSale.Visible =
		AccessRight("Insert", Metadata.Documents.SaleAdjustment)
		And AccessRight("Update", Metadata.Documents.CustomerInvoice);
	Items.ListSaleAdjustmentsCreateBasedOnTheCompletedWorkReport.Visible =
		AccessRight("Insert", Metadata.Documents.SaleAdjustment)
		And AccessRight("Update", Metadata.Documents.CustomerInvoiceServices);
	Items.ListSaleAdjustmentsCreateBasedOnTheSaleOfServicesOtherAssets.Visible =
		AccessRight("Insert", Metadata.Documents.SaleAdjustment)
		And AccessRight("Update", Metadata.Documents.CustomerInvoiceServicesAndAssets);
	Items.ListSaleAdjustmentsCreateBasedOnImplementationBeforeEnteringBalance.Visible = 
		AccessRight("Insert", Metadata.Documents.SaleAdjustment)
		And AccessRight("Update", Metadata.Documents.SourceDocument)
		And GetFunctionalOption("NewOnlineARAPAccounting");
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.ListSaleAdjustments.CommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.AListOfAdjustmentsToTheImplementationOfTheGroupGlobalTeam);
	// End IntegrationWith1CDocumentManagementSubsystem

	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "ListSaleAdjustments.Date", Items.ListSaleAdjustmentsDate.Name);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	If GetFunctionalOption("UseTollManufacturing2_5")
		And AccessRight("Insert", Metadata.Documents.SaleAdjustment)
		And AccessRight("Update", Metadata.Documents.ReportToMaterialProvider2_5) Then
		
		NewCommand = Commands.Add("CreateReportBasedOnGiver");
		NewCommand.Title = NStr("vi = 'Điều chỉnh bảng kê dành cho bên thuê gia công';
								|ru = 'Корректировку отчета давальцу';
								|en = 'Adjustment of ""Consumption report — Subcontracting services delivered""'; fa = 'Adjustment of ""Consumption report — Subcontracting services delivered""';
								|it = 'Rettifica del report al datore';
								|pl = 'Korektę raportu do właściciela surowców';
								|tr = 'Tüketim raporu-Verilen fason hizmetlerini düzeltme'");
		NewCommand.Action = "CreateReportBasedOnGiver";

		NewItem = Items.Add("CreateReportBasedOnGiver", Type("FormButton"),
			Items.AListOfAdjustmentsToTheImplementationGroupToCreate);
		
		NewItem.Type    = FormButtonType.CommandBarButton; // button type
		NewItem.CommandName = "CreateReportBasedOnGiver";
		
	EndIf;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	Manager = Settings.Get("Manager");
	
	CommonClientServer.SetDynamicListFilterItem(ListSaleAdjustments, "Manager", Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ManagerOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(ListSaleAdjustments, "Manager", Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListSaleAdjustments

&AtClient
Procedure ListSaleAdjustmentsOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListSaleAdjustmentsOnChange(Item)
	ProvisionInDocumentsClient.CheckToRunBackgroundInventoryAllocationJob();
EndProcedure

&AtServerNoContext
Procedure ListSaleAdjustmentsOnGetDataAtServer(TagName, Settings, Rows)
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateOnBasisOfGoodsServicesSale(Command)
	
	OpenForm("Document.SaleAdjustment.ObjectForm",
		New Structure("Basis", PredefinedValue("Document.CustomerInvoice.EmptyRef")));
	
EndProcedure

&AtClient
Procedure CreateBasedOnTheCompletedWorkReport(Command)
	
	OpenForm("Document.SaleAdjustment.ObjectForm",
		New Structure("Basis", PredefinedValue("Document.CustomerInvoiceServices.EmptyRef")));
	
EndProcedure

&AtClient
Procedure CreateBasedOnTheSaleOfServicesOtherAssets(Command)
	
	OpenForm("Document.SaleAdjustment.ObjectForm",
		New Structure("Basis", PredefinedValue("Document.CustomerInvoiceServicesAndAssets.EmptyRef")));
	
EndProcedure

&AtClient
Procedure CreateBasedOnImplementationBeforeEnteringBalance(Command)
	
	FillingValues = New Structure();
	FillingValues.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.AdjustBeforeEnteringBalance"));
	
	OpenForm("Document.SaleAdjustment.ObjectForm",
		New Structure("FillingValues", FillingValues));
	
EndProcedure
&AtClient
Procedure CreateReportBasedOnGiver(Command)
	
	OpenForm("Document.SaleAdjustment.ObjectForm",
		New Structure("Basis", PredefinedValue("Document.ReportToMaterialProvider2_5.EmptyRef")));
	
EndProcedure
// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.ListSaleAdjustments);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.ListSaleAdjustments);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.ListSaleAdjustments);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.ListSaleAdjustments);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure


&AtClient
Procedure ListSaleAdjustmentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.ListOfImplementationAdjustmentsStateOfTheEDVersion Then
	EndIf;
	
EndProcedure

#EndRegion
