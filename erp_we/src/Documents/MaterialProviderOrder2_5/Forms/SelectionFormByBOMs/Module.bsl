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
	
	ManufacturedProduct.Load(GetFromTempStorage(Parameters.AddressInTempStorage.ManufacturedProduct));
	
	Filter = New Structure("BillOfMaterials", Catalogs.BillsOfMaterials.EmptyRef());
	If ManufacturedProduct.FindRows(Filter).Count() = 0 Then
		Items.ErrorInformationGroup.Visible = False;
	EndIf;
	
	BOMList = Parameters.BOMList;
	EmptySpecification = BOMList.Find(Catalogs.BillsOfMaterials.EmptyRef());
	If Not EmptySpecification = Undefined Then
		BOMList.Delete(EmptySpecification);
	EndIf;
	
	Parameters.Property("OrderDate"             , OrderDate);
	Parameters.Property("LineOfBusiness", LineOfBusiness);
	
	Items.AllocatedMaterialsBillOfMaterials.ChoiceList.LoadValues(BOMList);
	Items.FilterByBillOfMaterials.ChoiceList.LoadValues(BOMList);
	
	FillInDataTables();
	
	EstablishSelectionOfMaterials(Items, FilterByBillOfMaterials);

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit And MoveToDocument Then
		GoodsAddressInStorage = PutProductsInStorage();
		NotifyChoice(New Structure("GoodsAddressInStorage", GoodsAddressInStorage));
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified Then
		
		If Exit Then
			
			WarningText = NStr("vi = 'Dữ liệu đã được thay đổi.
				|Trước khi kết thúc công việc, nên lưu lại thay đổi,
				|nếu không những dữ liệu đã thay đổi sẽ bị mất.';
				|ru = 'Данные были изменены.
				|Перед завершением работы рекомендуется сохранить изменения,
				|иначе измененные данные будут утеряны.';
				|en = 'Data has changed.
				|Save the changes before exiting, 
				|otherwise the changed data will be lost.'; fa = 'Data has changed.
				|Save the changes before exiting, 
				|otherwise the changed data will be lost.';
				|it = 'I dati sono stati modificati.
				|Prima di terminare il lavoro è consigliabile salvare le modifiche,
				|altrimenti i dati modificati verranno persi.';
				|pl = 'Dane zostały zmienione.
				|Zaleca się zapisanie zmian przed zakończeniem pracy,
				|w przeciwnym razie zmienione dane zostaną utracone.';
				|tr = 'Veriler değiştirilmiştir.
				| Çalışmayı tamamlamadan önce değişiklikleri kaydetmeniz önerilmektedir,
				| aksi takdirde değiştirilen veriler kaybolacaktır.'");
			
			Return;
			
		Else
			
			If Not MoveToDocument Then // The "Transfer to document" button is not pressed, simple closing
			
				Cancel = True;
				
				QueryText = NStr("vi = 'Từ chối thay đổi và chuyển đến chứng từ?';
								|ru = 'Отказаться от переноса изменений и перейти в документ?';
								|en = 'Cancel change transfer and go to the document?'; fa = 'Cancel change transfer and go to the document?';
								|it = 'Rifiutare il trasferimento delle modifiche e passare al documento?';
								|pl = 'Zrezygnować z przenoszenia zmian i przejść do dokumentu?';
								|tr = 'Değişiklikleri taşımaktan ve belgeye gitmekten vazgeçilsin mi?'");
				
				ButtonsList = New ValueList;
				ButtonsList.Add("DoNotSend", NStr("vi = 'Từ chối chuyển sang';
													|ru = 'Отказаться от переноса';
													|en = 'Reject transfer'; fa = 'Reject transfer';
													|it = 'Rifiutare il trasferimento';
													|pl = 'Zrezygnować z przeniesienia';
													|tr = 'Taşımaktan vazgeç'"));
				ButtonsList.Add("MoveTo_",  NStr("vi = 'Chuyển sang';
												|ru = 'Перенести';
												|en = 'Transfer'; fa = 'انتقال';
												|it = 'Spostare';
												|pl = 'Przenieś';
												|tr = 'Taşı'"));
				ButtonsList.Add("Cancel",     NStr("vi = 'Hủy bỏ';
													|ru = 'Отмена';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annulla';
													|pl = 'Anuluj';
													|tr = 'İptal'"));
				
				ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject), QueryText, ButtonsList);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = "MoveTo_" Then
		MoveToDocument = True;
		Close();
	ElsIf QuestionResult = "DoNotSend" Then
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SelectionByProductInCaseOfChange(Item)
	
	EstablishSelectionOfMaterials(Items, FilterByBillOfMaterials);
	
EndProcedure

&AtClient
Procedure ProductSelectionCleaning(Item, StandardProcessing)
	
	StandardProcessing = False;
	FilterByBillOfMaterials = Undefined;
	EstablishSelectionOfMaterials(Items, FilterByBillOfMaterials);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAllocatedMaterials

&AtClient
Procedure AllocatedMaterialsCountOnChange(Item)
	
	CurrentRow = Items.AllocatedMaterials.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure AllocatedMaterialsAfterDeleteRow(Item)
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure AllocatedMaterialsProductsOnChange(Item)
	
	CurrentRow = Items.AllocatedMaterials.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", 	CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);

	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "AllocatedMaterials"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure AllocatedMaterialsOnStartEdit(Item, NewRow, Copy)
	
	CurrentRow = Items.AllocatedMaterials.CurrentData;
	
	If NewRow Then
		
		CurrentRow.RowCode = 0;
		CurrentRow.BillOfMaterials = FilterByBillOfMaterials;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AllocatedMaterialsOnEditEnd(Item, NewRow, CancelEdit)
	
	Modified = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	
	MoveToDocument = True;
	Close();
	
EndProcedure

&AtClient
Procedure SortByMaterials(Command)
	
	AllocatedMaterials.Sort("Products, Characteristic, BillOfMaterials");
	
EndProcedure

&AtClient
Procedure SortByBOM(Command)
	
	AllocatedMaterials.Sort("BillOfMaterials, Products, Characteristic");
	
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

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisForm, "AllocatedMaterialsCharacteristic", "AllocatedMaterials.ItemVariantsAreUsed");

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AllocatedMaterialsBillOfMaterials.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FilterByBillOfMaterials");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("Enabled", False);

EndProcedure

#Region Other

&AtClientAtServerNoContext
Procedure EstablishSelectionOfMaterials(Items, BillOfMaterials)
	
	If Not ValueIsFilled(BillOfMaterials) Then // All lines of materials.
		RowFilter = New FixedStructure;
	Else
		RowFilter = New FixedStructure("BillOfMaterials", BillOfMaterials);
	EndIf;
	
	Items.AllocatedMaterials.RowFilter = RowFilter;
	
EndProcedure

&AtServer
Procedure FillInDataTables()
	
	ItemList = Catalogs.BillsOfMaterials.ItemList();
	KeyArray = New Array;
	
	For Each RowTS In ManufacturedProduct Do
		
		NewRow = ItemList.Add();
		FillPropertyValues(NewRow, RowTS, "Products,Characteristic,Count,BillOfMaterials");
		NewRow.ProductionStart      = OrderDate;
		NewRow.LineOfBusiness = LineOfBusiness;
		
		KeyArray.Add(RowTS.BillOfMaterials);
		
	EndDo;
	
	SpecificationMaterials = AllocatedMaterials.Unload(,
			"Products, Characteristic, BillOfMaterials, Package, NumberOfPackages, ItemsType, Count");
	
	SpecificationParameters = New Structure;
	SpecificationParameters.Insert("ListOfData",     "MaterialsAndServices,IncomingProducts");
	SpecificationParameters.Insert("KeyArray",	     KeyArray);
	SpecificationParameters.Insert("ItemList", ItemList);
	SpecificationParameters.Insert("Department",	     Parameters.Department);
	
	Documents.MaterialProviderOrder2_5.MaterialsAccordingToSpecifications(SpecificationParameters, SpecificationMaterials);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TT.Products,
	|	TT.Characteristic,
	|	TT.Count,
	|	TT.NumberOfPackages,
	|	TT.Package,
	|	TT.BillOfMaterials
	|INTO TTMaterials
	|FROM
	|	&UsedMaterials AS TT
	|
	|INDEX BY
	|	BillOfMaterials,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.Products,
	|	TT.Characteristic,
	|	TT.Count,
	|	TT.Package,
	|	TT.BillOfMaterials,
	|	TT.ItemsType
	|INTO TTSpecifications
	|FROM
	|	&SpecificationMaterials AS TT
	|
	|INDEX BY
	|	BillOfMaterials,
	|	Products,
	|	Characteristic,
	|	ItemsType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(DocMaterials.BillOfMaterials,   MaterialsSpec.BillOfMaterials)   AS BillOfMaterials,
	|	ISNULL(DocMaterials.Products,   MaterialsSpec.Products)   AS Products,
	|	ISNULL(DocMaterials.Characteristic, MaterialsSpec.Characteristic) AS Characteristic,
	|	ISNULL(DocMaterials.Package,       MaterialsSpec.Package)       AS Package,
	|	ISNULL(DocMaterials.Count,         0)                        AS Count,
	|	ISNULL(DocMaterials.NumberOfPackages, 0)                        AS NumberOfPackages,
	|	ISNULL(MaterialsSpec.Count,        0)                        AS CountPlan
	|FROM
	|	TTMaterials AS DocMaterials
	|		FULL JOIN TTSpecifications AS MaterialsSpec
	|		ON DocMaterials.BillOfMaterials   = MaterialsSpec.BillOfMaterials
	|		 AND DocMaterials.Products   = MaterialsSpec.Products
	|		 AND DocMaterials.Characteristic = MaterialsSpec.Characteristic
	|WHERE
	|	MaterialsSpec.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|";

	TableOfMaterials = GetFromTempStorage(Parameters.AddressInTempStorage.UsedMaterials);
	TableOfMaterials.GroupBy(
		"Products, Characteristic, Package, ItemsType, BillOfMaterials", 
		"NumberOfPackages, Count");
		
	FoundRows = TableOfMaterials.FindRows(
							New Structure("BillOfMaterials", Catalogs.BillsOfMaterials.EmptyRef()));
	If FoundRows.Count() > 0 Then
		For Each RowToDelete In FoundRows Do
			TableOfMaterials.Delete(RowToDelete);
		EndDo;
	EndIf;
	
	Query.SetParameter("SpecificationMaterials", SpecificationMaterials);
	Query.SetParameter("UsedMaterials", TableOfMaterials);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");

	// Fill in the attribute characteristics are used for materials
	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	
	RowsToProcess = New Array();
	
	While Selection.Next() Do
		
		NewRow = AllocatedMaterials.Add();
		FillPropertyValues(NewRow, Selection);
		
		RowsToProcess.Add(NewRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		AllocatedMaterials,
		CachedValues);
	
	AllocatedMaterials.Sort("BillOfMaterials, Products, Characteristic");
	
EndProcedure

&AtServer
Function PutProductsInStorage()
	
	Goods = AllocatedMaterials.Unload();
	GoodsAddressInStorage = PutToTempStorage(Goods, UUID);
	
	Return GoodsAddressInStorage;
	
EndFunction

#EndRegion

#EndRegion
