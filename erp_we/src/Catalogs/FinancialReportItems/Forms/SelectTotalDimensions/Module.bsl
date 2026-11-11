
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ItemsTree = GetFromTempStorage(Parameters.AddressOfReportItems); // See BudgetReportingCacheCalculationServer.BudgetItemTree
	If ValueIsFilled(Parameters.ItemTableAddress) Then
		TableOfElements = GetFromTempStorage(Parameters.ItemTableAddress); // See BudgetReportingCacheCalculationServer.NewTableOfElements
	Else
		TableOfElements = Undefined;
	EndIf;
	
	If TableOfElements = Undefined Then
		
		TreeRow = ItemsTree.Rows.Find(Parameters.AddressOfEditedItem,
			"AddressOfItemStructure", True);
		RootItem = FinancialReportingServer.RootItem(TreeRow,
			ItemKind("TableIndicatorsInRows"));
		SourceOfSubordinates = Undefined;
		If RootItem <> Undefined Then
			SourceOfSubordinates = FinancialReportingServer.SubordinateItem(RootItem,
				"ItemKind", ItemKind("Columns"));
			Overlying = "Rows";
			Underlying = "Columns";
		EndIf;
		RootItem = FinancialReportingServer.RootItem(TreeRow,
			ItemKind("TableIndicatorsInColumns"));
		If RootItem <> Undefined Then
			SourceOfSubordinates = FinancialReportingServer.SubordinateItem(RootItem,
				"ItemKind", ItemKind("Rows"));
			Overlying = "Columns";
			Underlying = "Rows";
		EndIf;
		If SourceOfSubordinates = Undefined Then
			SourceOfSubordinates = FinancialReportingServer.RootItem(TreeRow);
			Overlying = "Rows";
			Underlying = Undefined;
		EndIf;
		
		SupplementWithHigherDimensions(TreeRow, Overlying);
		ListUnderlyingDimensions(TreeRow, Overlying);
		If Underlying <> Undefined Then
			ListUnderlyingDimensions(SourceOfSubordinates, Underlying);
		Else
			TotalKind = 1;
			Items.TotalKind.Enabled = False;
		EndIf;
		
	Else
		
		MatrixCell = TableOfElements.Find(Parameters.AddressOfEditedItem, "Item");
		
		TreeRow = ItemsTree.Rows.Find(MatrixCell.String, "AddressOfItemStructure", True);
		SupplementWithHigherDimensions(TreeRow, "Rows");
		ListUnderlyingDimensions(TreeRow, "Rows");
		
		TreeColumn = ItemsTree.Rows.Find(MatrixCell.Column, "AddressOfItemStructure", True);
		SupplementWithHigherDimensions(TreeColumn, "Columns");
		ListUnderlyingDimensions(TreeColumn, "Columns");
		
	EndIf;
	
	SetSelectedMeasurements();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseAdvancedFeatures(Command)
	
	FormControl();
	
EndProcedure

&AtClient
Procedure TotalKindOnChange(Item)
	
	SetCaptionText();
	SetSelectedMeasurements();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	Close(MeasurementList());
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function MeasurementList()
	
	Array = SelectDimensions.Unload(New Structure("Flag", True)).UnloadColumn("DimensionID");
	Return StrConcat(Array, ", ");
	
EndFunction

&AtServer
Procedure SupplementWithHigherDimensions(Val TreeRow, Source)
	
	While TreeRow <> Undefined
		And TreeRow.ItemKind <> ItemKind("Rows")
		And TreeRow.ItemKind <> ItemKind("Columns") Do
		
		If TreeRow.ItemKind = ItemKind("Dimension") Then
			
			Presentation = PresentationDimensionID(TreeRow, False);
			Id = PresentationDimensionID(TreeRow, True);
			
			If SelectDimensions.FindRows(New Structure("DimensionID", Id)).Count() Then
				Continue;
			EndIf;
			
			NewRow = SelectDimensions.Add();
			NewRow.MeasurementView = Presentation;
			NewRow.DimensionID = Id;
			NewRow.DimensionSource = Source;
			
		EndIf;
		
		TreeRow = TreeRow.Parent;
		
	EndDo;
	
EndProcedure

&AtServer
Function AttributeValue(TreeRow, Var_AttributeName)
	
	If ValueIsFilled(TreeRow.AddressOfItemStructure) Then
		Value = FinancialReportingServerCall.ValueOfAdditionalProps(
					TreeRow.AddressOfItemStructure, Var_AttributeName);
	Else
		Value = FinancialReportingServerCall.ValueOfAdditionalProps(
					TreeRow.ReportItem, Var_AttributeName);
	EndIf;
	
	Return Value;
	
EndFunction

&AtServer
Function PresentationDimensionID(TreeRow, ThisIsID = False)
	
	DimensionType = AttributeValue(TreeRow, "DimensionType");
	
	If DimensionType = Enums.TypesOfBudgetReportDimensions.Period Then
		
		Periodicity = AttributeValue(TreeRow, "Periodicity");
		If ThisIsID Then
			Value = Common.EnumerationValueName(Periodicity);
		Else
			Value = String(Periodicity);
		EndIf;
		
	ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Organization Then
		
		If ThisIsID Then
			Value = "Organization";
		Else
			Value = BudgetReportingClientServer.PresentationOfBudgetingDimension("Organization");
		EndIf;
		
	ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Department Then
		
		If ThisIsID Then
			Value = "Department";
		Else
			Value = BudgetReportingClientServer.PresentationOfBudgetingDimension("Department");
		EndIf;
		
	ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Scenario Then
		
		If ThisIsID Then
			Value = "Scenario";
		Else
			Value = BudgetReportingClientServer.PresentationOfBudgetingDimension("Scenario");
		EndIf;
		
	ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Currency Then
		
		If ThisIsID Then
			Value = "Currency";
		Else
			Value = BudgetReportingClientServer.PresentationOfBudgetingDimension("Currency");
		EndIf;
		
	ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.RegisterDimension Then
		
		DimensionName = AttributeValue(TreeRow, "DimensionName");
		If ThisIsID Then
			Value = DimensionName;
		Else
			Value = BudgetReportingClientServer.PresentationOfBudgetingDimension(DimensionName);
		EndIf;
		
	ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Dimension
		Or DimensionType = Enums.TypesOfBudgetReportDimensions.FixedDimension Then
		
		DimensionKind = AttributeValue(TreeRow, "DimensionKind");
		If ThisIsID Then
			Value = Common.ObjectAttributeValue(DimensionKind, "Id");
		Else
			Value = String(DimensionKind);
		EndIf;
		
	EndIf;
	
	Return Value;
	
EndFunction

&AtServer
Procedure ListUnderlyingDimensions(Val TreeRow, Source)
	
	For Each SubordinateRow In TreeRow.Rows Do
		
		If SubordinateRow.ItemKind = ItemKind("Dimension") Then
			
			Presentation = PresentationDimensionID(SubordinateRow, False);
			Id = PresentationDimensionID(SubordinateRow, True);
			
			If SelectDimensions.FindRows(New Structure("DimensionID", Id)).Count() Then
				Continue;
			EndIf;
			
			NewRow = SelectDimensions.Add();
			NewRow.MeasurementView = Presentation;
			NewRow.DimensionID = Id;
			NewRow.DimensionSource = Source;
			
		EndIf;
		
		ListUnderlyingDimensions(SubordinateRow, Source);
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function ItemKind(TagName)
	
	#If Client Then
		Return PredefinedValue("Enum.FinancialReportItemKinds." + TagName);
	#Else
		Return Enums.FinancialReportItemKinds[TagName];
	#EndIf
	
EndFunction

&AtServer
Procedure FormControl()
	
	If Items.UseAdvancedFeatures.Title = NStr("vi = 'Sử dụng các tính năng nâng cao';
												|ru = 'Использовать расширенные возможности';
												|en = 'Use advanced features'; fa = 'استفاده از قابلیت‌های پیشرفته';
												|it = 'Usare opzioni avanzate';
												|pl = 'Używaj rozszerzonych możliwości';
												|tr = 'Gelişmiş seçenekleri kullan'") Then
		Items.UseAdvancedFeatures.Title = NStr("vi = 'Sử dụng các tính năng đơn giản';
												|ru = 'Использовать упрощенные возможности';
												|en = 'Use simplified features'; fa = 'استفاده از قابلیت‌های ساده‌شده';
												|it = 'Usare opzioni semplificati';
												|pl = 'Są używane uproszczone możliwości';
												|tr = 'Basitleştirilmiş imkânları kullan'");
		Items.Pages.CurrentPage = Items.DetailedSetting;
	Else
		Items.UseAdvancedFeatures.Title = NStr("vi = 'Sử dụng các tính năng nâng cao';
												|ru = 'Использовать расширенные возможности';
												|en = 'Use advanced features'; fa = 'استفاده از قابلیت‌های پیشرفته';
												|it = 'Usare opzioni avanzate';
												|pl = 'Używaj rozszerzonych możliwości';
												|tr = 'Gelişmiş seçenekleri kullan'");
		Items.Pages.CurrentPage = Items.SimpleSetup;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetCaptionText()
	
	If TotalKind = 0 Then
		Items.CaptionSummary.Title = NStr("vi = 'Hàm sẽ trả về tổng cộng tất cả các giá trị trên dòng báo cáo';
											|ru = 'Функция вернет итог по всем значениям по строке отчета';
											|en = 'The function will return total by all values by the report line'; fa = 'تابع جمع همه مقادیر سطر گزارش را برمی‌گرداند';
											|it = 'Funzione riporterà il totale di tutti i valori per riga di report';
											|pl = 'Funkcja zwróci wynik dla wszystkich wartości w wierszu raportu';
											|tr = 'Bu fonksiyon, satırına göre tüm rapor değerlerinin toplamına döner'");
	Else
		Items.CaptionSummary.Title = NStr("vi = 'Hàm sẽ trả về tổng cộng tất cả các giá trị trong cột báo cáo';
											|ru = 'Функция вернет итог по всем значениям по колонке отчета';
											|en = 'The function will return total by all values by the report column'; fa = 'The function will return total by all values by the report column';
											|it = 'La funzione riporterà il totale di tutti i valori per colonna di report';
											|pl = 'Funkcja zwróci wynik dla wszystkich wartości w kolumnie raportu';
											|tr = 'Bu fonksiyon, sütununa göre tüm rapor değerlerinin toplamına döner'");
	EndIf;
	
EndProcedure

&AtServer
Procedure SetSelectedMeasurements()
	
	If TotalKind Then
		Source = "Rows";
	Else
		Source = "Columns";
	EndIf;
	
	For Each SearchString In SelectDimensions Do
		
		SearchString.Flag = SearchString.DimensionSource = Source;
		
	EndDo;
	
EndProcedure

#EndRegion

