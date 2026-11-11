
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SetConditionalAppearance();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.DocumentsList.CommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	Items.GroupCreate.Visible = AccessRight("Insert", Metadata.Documents.OtherIncomeExpenses);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(
		ThisObject,
		Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CompanyFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(DocumentsList, "Organization", Organization, DataCompositionComparisonType.Equal,, ValueIsFilled(Organization));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDocumentsList

&AtClient
Procedure DocumentsListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.DocumentsList);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.DocumentsList, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.DocumentsList);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Items.DocumentsList);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure CreateIncomeReclassification(Command)
	
	CreateDocument(PredefinedValue("Enum.BusinessTransactions.IncomeReclassification"));
	
EndProcedure

&AtClient
Procedure CreateExpenseReclassification(Command)
	
	CreateDocument(PredefinedValue("Enum.BusinessTransactions.ExpenseReclassification"));
	
EndProcedure

&AtClient
Procedure CreateAnExpenseWriteOff(Command)
	
	CreateDocument(PredefinedValue("Enum.BusinessTransactions.WriteOffOtherExpenses"));
	
EndProcedure

&AtClient
Procedure CreateRevenueRegistration(Command)
	
	CreateDocument(PredefinedValue("Enum.BusinessTransactions.OtherIncome"));
	
EndProcedure

&AtClient
Procedure CreateACostReversal(Command)
	
	CreateDocument(PredefinedValue("Enum.BusinessTransactions.ReversalOfOtherExpenses"));
	
EndProcedure

&AtClient
Procedure CreateIncomeReversal(Command)
	
	CreateDocument(PredefinedValue("Enum.BusinessTransactions.ReversalOfOtherIncome"));
	
EndProcedure

&AtClient
Procedure CreateExpenseTransferBetweenBranches(Command)
	CreateDocument(PredefinedValue("Enum.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices"));
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DocumentsListBusinessOperation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DocumentsList.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.OtherExpenses;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ghi nhận chi phí';
													|ru = 'Регистрация расходов';
													|en = 'Expense registration'; fa = 'ثبت هزینه';
													|it = 'Registrazione delle spese';
													|pl = 'Rejestracja wydatków';
													|tr = 'Giderlerin kayıtları'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DocumentsListBusinessOperation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DocumentsList.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.OtherIncome;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ghi nhận thu nhập';
													|ru = 'Регистрация доходов';
													|en = 'Income registration'; fa = 'ثبت درآمد';
													|it = 'Registrazione dei ricavi';
													|pl = 'Rejestracja dochodów';
													|tr = 'Gelirlerin kayıtları'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DocumentsListBusinessOperation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DocumentsList.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.WriteOffOtherExpenses;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ghi giảm chi phí';
													|ru = 'Списание расходов';
													|en = 'Expense write-off'; fa = 'اسقاط هزینه';
													|it = 'Storno delle spese';
													|pl = 'Wyksięgowanie wydatków';
													|tr = 'Giderlerin silinmesi'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DocumentsListBusinessOperation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DocumentsList.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.ReversalOfOtherIncome;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Thu nhập đảo ngược';
													|ru = 'Сторнирование доходов';
													|en = 'Income reversal'; fa = 'برگشت درآمد';
													|it = 'Storno dei ricavi';
													|pl = 'Stornowanie dochodów';
													|tr = 'Gelirlerin iptali'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DocumentsListBusinessOperation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DocumentsList.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.ReversalOfOtherExpenses;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Đảo ngược chi phí';
													|ru = 'Сторнирование расходов';
													|en = 'Expense reversal'; fa = 'برگشت هزینه';
													|it = 'Storno di spese';
													|pl = 'Stornowanie wydatków';
													|tr = 'Giderlerin iptali'"));
	
	//
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "DocumentsList.Date", Items.DocumentsListDate.Name);
	
EndProcedure

&AtClient
Procedure CreateDocument(BusinessOperation)
	
	ParametersStructure1 = New Structure;
	ParametersStructure1.Insert("Basis", New Structure("BusinessOperation", BusinessOperation));
	OpenForm("Document.OtherIncomeExpenses.ObjectForm", ParametersStructure1, Items.DocumentsList);
	
EndProcedure

#EndRegion
