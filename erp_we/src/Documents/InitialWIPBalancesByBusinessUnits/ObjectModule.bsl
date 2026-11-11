#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure")
		And FillingData.Property("HeaderAttributes") Then
		FillPropertyValues(ThisObject, FillingData.HeaderAttributes);
	EndIf;
	
	InitializeDocument(FillingData);
	
	ItemsAndDimensionsSelectionParameters = Documents.InitialWIPBalancesByBusinessUnits.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	InitializeDocument();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	CostsServer.CheckUseOfBatchAccounting22(ThisObject, Date, Cancel);
	
	#Region Table_Costs
	
	NotCheckedAttributeArray.Add("Costs.ExpenseItem");
	NotCheckedAttributeArray.Add("Costs.RuleOfCostAllocatingToProductionLotsMan");
	NotCheckedAttributeArray.Add("Costs.RuleOfCostAllocatingToProductionLotsLocal");
	
	Query = New Query;
	Query.Text = 
		"SELECT DISTINCT
		|	ExpenseItems.Ref AS ExpenseItem,
		|	CASE
		|		WHEN ExpenseItems.CostAllocationOptionManag IN (VALUE(Enum.CostAllocationOptions.ToProductionCosts), VALUE(Enum.CostAllocationOptions.DoNotAllocate))
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS CheckManRule,
		|	CASE
		|		WHEN ExpenseItems.CostAllocationOptionLocal IN (VALUE(Enum.CostAllocationOptions.ToProductionCosts), VALUE(Enum.CostAllocationOptions.DoNotAllocate))
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS CheckLocalRule
		|FROM
		|	ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
		|WHERE
		|	ExpenseItems.Ref IN(&ExpenseItems)";
	
	Query.SetParameter("ExpenseItems", Costs.UnloadColumn("ExpenseItem"));
	
	DetailsOfExpenditureItems = Query.Execute().Unload();
	DetailsOfExpenditureItems.Indexes.Add("ExpenseItem");
	
	MessageTemplate = NStr("vi = 'Trong dòng %LineNumber% của danh sách ""Chi phí"" chưa điền trường ""%FieldName%"".';
							|ru = 'В строке %LineNumber% списка ""Затраты"" не заполнено поле ""%FieldName%"".';
							|en = '""%FieldName%"" in line %LineNumber% of the list ""Costs"" is required.'; fa = '""%FieldName%"" in line %LineNumber% of the list ""Costs"" is required.';
							|it = 'Nella riga %LineNumber% dell''elenco ""Spese"" non è compilato il campo ""%FieldName%"".';
							|pl = 'W wierszu %LineNumber% listy „Straty” pole ""%FieldName%"" nie jest wypełnione.';
							|tr = '""Maliyetler"" listesinin %LineNumber% satırında ""%FieldName%"" alanı doldurulmadı.'");
	DataKey = TMCommonUse.DataKeyForMessageToUser(ThisObject);
	
	For Each CurRow In Costs Do
		
		If CurRow.ExpenseType = Enums.CostTypes.Other
			Or CurRow.ExpenseType = Enums.CostTypes.Depreciation Then
			
			MessageText = StrReplace(MessageTemplate, "%LineNumber%", CurRow.LineNumber);
			
			If Not ValueIsFilled(CurRow.ExpenseItem) Then
				
				ErrorMessage = StrReplace(MessageText, "%FieldName%", NStr("vi = 'Dạng chi phí';
																			|ru = 'Статья расходов';
																			|en = 'Expense item'; fa = 'قلم هزینه';
																			|it = 'Voce di spese';
																			|pl = 'Rodzaj kosztu';
																			|tr = 'Gider kalemi'"));
				Field = CommonClientServer.PathToTabularSection("Costs", CurRow.LineNumber, "ExpenseItem");
				Common.MessageToUser(ErrorMessage, DataKey , Field, "Object", Cancel);
				
				Continue;
				
			EndIf;
			
			ArticleDetails_1 = DetailsOfExpenditureItems.Find(CurRow.ExpenseItem);
			If ArticleDetails_1 = Undefined Then
				Continue;
			EndIf;
			
			If ArticleDetails_1.CheckManRule
				And Not ValueIsFilled(CurRow.RuleOfCostAllocatingToProductionLotsMan) Then
				
				ErrorMessage = StrReplace(MessageText, "%FieldName%", NStr("vi = 'Quy tắc phân bổ chi phí xuất xưởng (qt)';
																			|ru = 'Правило отнесения на выпуск (упр.)';
																			|en = 'Rule of allocating to release (mgmt)'; fa = 'قاعده تسهیم به تولید (مدیریت)';
																			|it = 'Regola dell''attribuzione al rilascio (ges.)';
																			|pl = 'Zasada przydzielania do wyprodukowania (zarz.)';
																			|tr = 'Üretim için ilişkilendirme kuralı (yerel muhasebe.)'"));
				Field = CommonClientServer.PathToTabularSection("Costs", CurRow.LineNumber, "RuleOfCostAllocatingToProductionLotsMan");
				Common.MessageToUser(ErrorMessage, DataKey , Field, "Object", Cancel);
				
			EndIf;
			
			If ArticleDetails_1.CheckLocalRule
				And Not ValueIsFilled(CurRow.RuleOfCostAllocatingToProductionLotsLocal) Then
				
				ErrorMessage = StrReplace(MessageText, "%FieldName%", NStr("vi = 'Quy tắc phân bổ chi phí xuất xưởng (pq)';
																			|ru = 'Правило отнесения на выпуск (регл.)';
																			|en = 'Rule of allocating to release (local)'; fa = 'قاعده تسهیم به تولید (محلی)';
																			|it = 'Regola dell''attribuzione al rilascio (reg.)';
																			|pl = 'Zasada przydzielania do wyprodukowania (reg.)';
																			|tr = 'Üretim için ilişkilendirme kuralı (yerel muhasebe.)'"));
				Field = CommonClientServer.PathToTabularSection("Costs", CurRow.LineNumber, "RuleOfCostAllocatingToProductionLotsLocal");
				Common.MessageToUser(ErrorMessage, DataKey , Field, "Object", Cancel);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	#EndRegion
	
	#Region ReviewArticlesAndAnalytics
	
	ItemsAndDimensionsSelectionParameters = Documents.InitialWIPBalancesByBusinessUnits.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	#EndRegion
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If DocumentsPosting.DocumentProperties(ThisObject).IsNew Then
		ThisObject.GetNewObjectRef();
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.InitialWIPBalancesByBusinessUnits.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	TypesOfItemByItemCosts = New Array;
	TypesOfItemByItemCosts.Add(Enums.CostTypes.Depreciation);
	TypesOfItemByItemCosts.Add(Enums.CostTypes.Other);
	
	For Each CostLine In Costs Do
		
		If TypesOfItemByItemCosts.Find(CostLine.ExpenseType) = Undefined Then
			Continue;
		EndIf;
		
		If Not ValueIsFilled(CostLine.RuleOfCostAllocatingToProductionLotsLocal) Then
			
			CostLine.AmountTemporaryDifferences = 0;
			CostLine.AmountPermanentDifferences = 0;
			CostLine.SumCompl = 0;
			
		EndIf;
		
		If Not ValueIsFilled(CostLine.RuleOfCostAllocatingToProductionLotsMan) Then
			CostLine.Sum = 0;
		EndIf;
		
	EndDo;
	
	DocumentAmount = Costs.Total("Sum");
	
	// Processing the change of details
	If Not IsNew() Then
		PreviousValues1 = Common.ObjectAttributesValues(Ref, "DeletionMark");
		AdditionalProperties.Insert("DeletionMarkBeforeRecording", PreviousValues1.DeletionMark);
	Else
		AdditionalProperties.Insert("DeletionMarkBeforeRecording", False);
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region FillType

Procedure InitializeDocument(FillingData = Undefined)
	
	Date			= CurrentSessionDate();
	Organization		= SettingsValueCached.GetDefaultOrganization(Organization);
	PriceKind			= Catalogs.TypesOfPrices.TypeOfPricePlannedCostOfInventory(PriceKind);
	EmployeeResponsible	= Users.CurrentUser();
	
EndProcedure

#EndRegion

#EndRegion

#EndIf