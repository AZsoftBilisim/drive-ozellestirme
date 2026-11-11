#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Not GetFunctionalOption("UseProduction") Then
		Items.GroupItemByItemConstants.Visible = False;
		Items.GroupItemVariables.Visible = False;
		Items.LaborCostsGroup.Visible = False;
	EndIf;
	
	If Not GetFunctionalOption("UseExcisableGoods") Then
		Items.ExciseTaxesGroup.Visible = False;
	EndIf;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	Value = Item.CurrentData[Field.Name];
	ShowValue(Undefined, Value);
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure DistributionByAreasOfActivity(Command)
	
	If Items.List.CurrentData = Undefined
	 Or Not ValueIsFilled(Items.List.CurrentData.Recorder) Then
		CommonClient.MessageToUser(NStr("ru = 'Необходимо указать регистратор для распределения';
										|vi = 'Specify the recorder for allocation';
										|en = 'Specify the recorder for allocation'; fa = 'Specify the recorder for allocation';
										|it = 'Specify the recorder for allocation';
										|pl = 'Specify the recorder for allocation';
										|tr = 'Dağıtım için kaydedici belirtilmelidir'"));
		Return;
	EndIf;
	
	Recorder = Items.List.CurrentData.Recorder;
	
	Table = DistributionByLineOfBusinessATServer(Items.List.CurrentData.Recorder);
	
	If Table = Undefined Then
		CommonClient.MessageToUser(NStr("ru = 'Нет движений для распределения по направлениям деятельности';
										|vi = 'There are no records for allocation by line of business';
										|en = 'There are no records for allocation by line of business'; fa = 'There are no records for allocation by line of business';
										|it = 'There are no records for allocation by line of business';
										|pl = 'There are no records for allocation by line of business';
										|tr = 'Faaliyet alanlarına göre dağıtım için hareket bulunmuyor'"));
	Else
		Table.Show(NStr("ru = 'Документ';
						|vi = 'Document';
						|en = 'Document'; fa = 'سند';
						|it = 'Document';
						|pl = 'Document';
						|tr = 'Belge'") + ": " + TrimAll(Recorder));
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function DistributionByLineOfBusinessATServer(DocumentRef)

	If Not CalculationOfCostCached.ThereAreDistributionSettingsForLinesOfBusiness()
	 Or Not GetFunctionalOption("GenerateFinancialResult") 
	 Or Not GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
		Return Undefined;
	EndIf;
	
	Query = CostCalculationCostAdjustment.PrepareRequestToFillInLinesOfBusiness(DocumentRef,, True);
	
	If Query = Undefined Then
		Return Undefined;
	EndIf;
	
	Query.Text =
	"SELECT
	|   DetailedRecords.RecNo AS LineNumber,
	|	DetailedRecords.LineOfBusinessAllocationMethod AS LineOfBusinessAllocationMethod,
	|	DetailedRecords.PartnerPriority + DetailedRecords.PriorityPartnerSegment + DetailedRecords.PriorityDivision
	|		+ DetailedRecords.PriorityItem + DetailedRecords.PriorityInventorySegment
	|		+ DetailedRecords.PriorityWarehouse + DetailedRecords.PriorityCompany AS OverallPriority,
	|
	|	DetailedRecords.PartnerPriority,
	|	DetailedRecords.PriorityPartnerSegment,
	|	DetailedRecords.PriorityItem,
	|	DetailedRecords.PriorityInventorySegment,
	|	DetailedRecords.PriorityWarehouse,
	|	DetailedRecords.PriorityDivision,
	|	DetailedRecords.PriorityCompany,
	|
	|	T.Partner,
	|	DetailedRecords.Partner AS DistributionRule_Partner,
	|	DetailedRecords.PartnerSegment AS DistributionRule_PartnerSegment,
	|	T.Products,
	|	DetailedRecords.Products AS DistributionRule_Item,
	|	DetailedRecords.ProductSegment AS DistributionRule_InventorySegment,
	|	T.Warehouse,
	|	DetailedRecords.Warehouse AS DistributionRule_Warehouse,
	|	T.Department,
	|	DetailedRecords.Department AS DistributionRule_Division,
	|	T.Organization,
	|	DetailedRecords.Organization AS DistributionRule_Company
	|FROM
	|	TTInitialRegisteredRecorded AS T
	|	INNER JOIN TTDistributionTableInDetail AS DetailedRecords
	|		ON DetailedRecords.RecNo = T.RecNo
	|WHERE
	|	T.FillInLineOfBusiness
	|ORDER BY
	|	LineNumber,
	|	OverallPriority DESC,
	|	LineOfBusinessAllocationMethod DESC
	|";
	
	DistributionTable_1 = Query.Execute().Unload();
	
	If Not ValueIsFilled(DistributionTable_1) Then
		Return Undefined;
	EndIf;
	
	Return TMCommonUse.TabularDocumentFromTableOfValues(DistributionTable_1);
	
EndFunction

#EndRegion
