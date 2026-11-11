
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	ChartOfAccounts = Parameters.ChartOfAccounts;
	If Parameters.Filter.Property("ChartOfAccounts") And ValueIsFilled(Parameters.Filter.ChartOfAccounts) Then
		ChartOfAccounts = Parameters.Filter.ChartOfAccounts;
		Parameters.Filter.Delete("ChartOfAccounts");
		Items.ChartOfAccounts.Enabled = False;
	EndIf;
	If Not ValueIsFilled(ChartOfAccounts) Then
		ChartOfAccounts = Catalogs.FinancialAccountingChartsOfAccounts.DefaultChartOfAccounts();
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(List, "AssetBalanceSheetName", NStr("vi = 'Tài sản';
																					|ru = 'Актив';
																					|en = 'Asset'; fa = 'دارایی';
																					|it = 'Attivo';
																					|pl = 'Asset';
																					|tr = 'Varlık'"));
	CommonClientServer.SetDynamicListParameter(List, "Liabilities", NStr("vi = 'Nguồn vốn';
																		|ru = 'Пассив';
																		|en = 'Liability'; fa = 'بدهی';
																		|it = 'Passività';
																		|pl = 'Liability';
																		|tr = 'Yükümlülük'"));
	CommonClientServer.SetDynamicListParameter(List, "AssetLiability", NStr("vi = 'Tài sản/Nguồn vốn';
																			|ru = 'Актив/Пассив';
																			|en = 'Asset/Liability'; fa = 'دارایی/بدهی';
																			|it = 'Attivo/passivo';
																			|pl = 'Aktywa/Pasywa';
																			|tr = 'Varlık/Yükümlülük'"));
	CommonClientServer.SetDynamicListParameter(List, "TurnoversOnly", " ("+NStr("vi = 'ps';
																				|ru = 'об';
																				|en = 'turn'; fa = 'turn';
																				|it = 'am';
																				|pl = 'turn';
																				|tr = 'hakkında'")+")");
	
	Parameters.Property("OnlyAllowed", OnlyAllowed);
	
	If Parameters.Property("ExtDimensionTypes") Then
		RepresentedAsList = True;
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Ref",
			ChartsOfAccounts.International.AccountingAccountsWithExtdimensionView(Parameters.ExtDimensionTypes),
			DataCompositionComparisonType.InList,,
			True);
	EndIf;
	
	If Not RepresentedAsList Then
		SelectionWithoutAffectingDisplay = New Array();
		SelectionWithoutAffectingDisplay.Add("ChartOfAccounts");
		SelectionWithoutAffectingDisplay.Add("OffBalance");
		
		For Each FilterElement In Parameters.Filter Do
			If SelectionWithoutAffectingDisplay.Find(FilterElement.Key) = Undefined Then
				RepresentedAsList = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	CurrentLanguageSuffix = NationalLanguageSupportServer.CurrentLanguageSuffix(); 
	ExtDimensionNameInCurrentLanguage = "InternationalExtdimensionDay.ExtDimensionType.Description" + CurrentLanguageSuffix;
	ExpressionNameOfExtDimension =
	"CASE 
	|	WHEN &ExtDimensionNameInCurrentLanguage <> """"
	|		THEN &ExtDimensionNameInCurrentLanguage
	|	ELSE InternationalExtdimensionDay.ExtDimensionType.Description
	|END"; 
	ExpressionNameOfExtDimension = StrReplace(ExpressionNameOfExtDimension, "&ExtDimensionNameInCurrentLanguage", ExtDimensionNameInCurrentLanguage);	
	List.QueryText = StrReplace(List.QueryText, "InternationalExtdimensionDay.ExtDimensionType.Description", ExpressionNameOfExtDimension); 

	Items.AccountingByLinesOfBusiness.Visible = Catalogs.LinesOfBusiness.AccountingByDirectionsIsUsed();
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If RepresentedAsList Then
		Items.List.Representation = TableRepresentation.List;
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(List, "ChartOfAccounts", ChartOfAccounts);
	CommonClientServer.SetDynamicListFilterItem(List, "ChartOfAccounts", ChartOfAccounts);
	
EndProcedure

&AtClient
Procedure ListValueChoice(Item, Value, StandardProcessing)
	
	If OnlyAllowed Then
		If TypeOf(Value) = Type("ChartOfAccountsRef.International") Then
			StandardProcessing = Not Item.RowData(Value).RestrictUseInPostings;
			
		ElsIf TypeOf(Value) = Type("Array") Then
			IndexOf = 0;
			While IndexOf <= Value.UBound() Do
				Account = Value[IndexOf];
				If Item.RowData(Account).RestrictUseInPostings Then
					Value.Delete(IndexOf);
					Continue;
				EndIf;
				IndexOf = IndexOf + 1;
			EndDo;
			
		EndIf;
	EndIf;// OnlyAllowed
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ChartOfAccountsOnChange(Item)
	
	CommonClientServer.SetDynamicListParameter(List, "ChartOfAccounts", ChartOfAccounts);
	CommonClientServer.SetDynamicListFilterItem(List, "ChartOfAccounts", ChartOfAccounts);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	If Not CheckFilling() Then
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion
