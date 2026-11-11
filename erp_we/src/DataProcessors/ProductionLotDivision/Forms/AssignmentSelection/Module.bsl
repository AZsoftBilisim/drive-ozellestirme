
#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If IsTempStorageURL(Parameters.AddressStandards)
		And IsTempStorageURL(Parameters.AddressSelected) Then
		
		TableStandards = GetFromTempStorage(Parameters.AddressStandards);
		TableMatched = GetFromTempStorage(Parameters.AddressSelected); //ValueTable
		TableMatched.Indexes.Add("Purpose");
		LineNumber = 1;
		
		For IndexOf = 0 To TableStandards.Count()-1 Do
			
			LineStandards = TableStandards[IndexOf];
			
			NewRow = Assignments.Add();
			NewRow.Products = Parameters.Products;
			NewRow.Package = Parameters.Package;
			NewRow.Purpose = LineStandards.Purpose;
			NewRow.QuantityStandard = LineStandards.Count;
			NewRow.PickUpImage = True;
			NewRow.LineNumber = LineNumber;
			
			FoundRow = TableMatched.Find(LineStandards.Purpose, "Purpose");
			If FoundRow <> Undefined Then
				NewRow.Count = FoundRow.Count;
			EndIf;
			
			LineNumber = LineNumber + 1;
			
		EndDo;
		
		If TableStandards.Find(Catalogs.Assignments.EmptyRef(), "Purpose") = Undefined Then
			
			NewRow = Assignments.Add();
			NewRow.Products = Parameters.Products;
			NewRow.Package = Parameters.Package;
			NewRow.LineNumber = LineNumber;
			
			FoundRow = TableMatched.Find(Catalogs.Assignments.EmptyRef(), "Purpose");
			If FoundRow <> Undefined Then
				NewRow.Count = FoundRow.Count;
			EndIf;
			
		EndIf;
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert(
			"RecalculateNumberOfPackages", 
			BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfNumberOfPackages());
		StructureOfActions.Insert("RecalculateNumberOfSuffixPacks","NormativeStandard");
		
		BatchProcessingOfTablePartServer.TreatTS(
			Assignments,
			StructureOfActions,
			BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues());
		
	EndIf;
	
	ProductData_1 = Common.ObjectAttributesValues(Parameters.Products,
		"Presentation, UnitOfMeasure.Presentation");
	Title = StrTemplate(NStr("vi = 'Chọn mục đích lô hàng (Sản phẩm: %1)';
							|ru = 'Подбор назначений партии (Изделие: %1)';
							|en = 'Lot assignment picking (Finished product: %1)'; fa = 'Lot assignment picking (Finished product: %1)';
							|it = 'Selezione delle assegnazioni dei lotti (Produzione: %1)';
							|pl = 'Wybór przeznaczeń partii (Wyrób: %1)';
							|tr = 'Lot atamalarının seçimi (Nihai ürün: %1)'"), ProductData_1.Presentation);
	
	PackagePresentation = ?(Parameters.Package.IsEmpty(),
		ProductData_1.UnitOfMeasurePresentation,
		Common.ObjectAttributeValue(Parameters.Package, "Presentation"));
	Items.Decoration1.Title = StrTemplate(NStr("vi = 'Cần chọn: %1 %2';
												|ru = 'Требуется подобрать: %1 %2';
												|en = 'Pick: %1 %2'; fa = 'انتخاب: %1 %2';
												|it = 'Si richiede di selezionare: %1%2';
												|pl = 'Należy wybrać: %1 %2';
												|tr = 'Seçilmesi gereken: %1 %2'"), 
		Parameters.NumberOfPackages,
		PackagePresentation);
	Items.AssignmentsNumberOfPackagesStandard.Title = StrTemplate(NStr("vi = 'Số lượng, %1';
																		|ru = 'Количество, %1';
																		|en = 'Quantity, %1'; fa = 'Quantity, %1';
																		|it = 'Quantità, %1';
																		|pl = 'Ilość, %1';
																		|tr = 'Miktar, %1'"),
		PackagePresentation);
	Items.GroupAssignmentsSelected.Title = StrTemplate(NStr("vi = 'Đã chọn, %1';
															|ru = 'Подобрано, %1';
															|en = 'Pick, %1'; fa = 'انتخاب، %1';
															|it = 'Selezionato, %1';
															|pl = 'Wybrano, %1';
															|tr = 'Seçildi, %1'"),
		PackagePresentation);
	
	CalculateTotal(ThisForm);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

&AtClient
Procedure AssignmentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "AssignmentsPickUpImage" Then
		
		StandardProcessing = False;
		String = Items.Assignments.CurrentData;
		String.Count = String.QuantityStandard;
		String.NumberOfPackages = String.NumberOfPackagesStandard;
		
		CalculateTotal(ThisForm);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AssignmentsNumberOfPackagesOnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	BatchProcessingOfTablePartClient.ProcessTSString(
		Items.Assignments.CurrentData,
		StructureOfActions,
		CachedValues);
	
	CalculateTotal(ThisForm);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Pick(Command)
	
	Close(CalculationResult1());
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AssignmentsPurpose.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Assignments.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không mục đích>';
													|ru = '<без назначения>';
													|en = '<No assignment>'; fa = '<No assignment>';
													|it = '<senza assegnazione>';
													|pl = '<bez przeznaczenia>';
													|tr = '<atamasız>'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AssignmentsPickUpImage.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Assignments.QuantityStandard");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateTotal(Form)
	
	Form.NumberOfPackagesTotal = 0;
	
	For Each String In Form.Assignments Do
		Form.NumberOfPackagesTotal = Form.NumberOfPackagesTotal + String.NumberOfPackages;
	EndDo;
	
EndProcedure

&AtServer
Function CalculationResult1()
	
	Count = 0;
	NumberOfPackages = 0;
	
	Rows = New Array;
	For Each String In Assignments Do
		If String.Count = 0 Then
			Continue;
		EndIf;
		Rows.Add(String);
		Count = Count + String.Count;
		NumberOfPackages = NumberOfPackages + String.NumberOfPackages;
	EndDo;
	
	Result = New Structure;
	Result.Insert("Count", Count);
	Result.Insert("NumberOfPackages", NumberOfPackages);
	
	Table = Assignments.Unload(Rows, "Purpose, Count");
	Result.Insert("DestinationAddress", PutToTempStorage(Table));
	
	Return Result;
	
EndFunction

#EndRegion
