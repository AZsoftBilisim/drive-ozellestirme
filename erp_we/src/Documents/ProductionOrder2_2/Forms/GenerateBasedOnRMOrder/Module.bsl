#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	FillInGoodsAccordingToDocument();
	
	CustomizeFormElements();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	For Each String In Goods.GetItems() Do
		Items.Goods.Expand(String.GetID(), True);
	EndDo;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsToOrderOnChange(Item)
	
	LineProducts_ = Items.Goods.CurrentData;
	LineProducts_.Mark = LineProducts_.ToOrder > 0;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CheckAll(Command)
	
	SelectOrClearAll(ThisObject, True);
	
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	
	SelectOrClearAll(ThisObject, False);
	
EndProcedure

&AtClient
Procedure CreateDocument(Command)
	
	Close(ResultIsAtServer());
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	//
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsMark.Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Show", False);
	
	//
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDescription.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Level");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.UnderRepairProduct");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<sản phẩm bất kỳ>';
																		|ru = '<любое изделие>';
																		|en = '<any product>'; fa = '<هر محصول>';
																		|it = '<any product>';
																		|pl = '<any product>';
																		|tr = '<herhangi bir ürün>'"));
	
EndProcedure

&AtServer
Procedure FillInGoodsAccordingToDocument()
	
	Query = New Query;
	Query.SetParameter("Ref", Parameters.DocumentReference);
	
	If TypeOf(Parameters.DocumentReference) = Type("DocumentRef.ProductionStage2_2") Then
		
		Query.Text = "
		|SELECT
		|	MIN(Table.LineNumber)                      AS LineNumber,
		|	Table.UnderRepairProduct          AS UnderRepairProduct,
		|	Table.UnderRepairVariant        AS UnderRepairVariant,
		|	Table.UnderRepairBatch                 AS UnderRepairBatch,
		|	Table.Products                              AS Products,
		|	Table.Characteristic                            AS Characteristic,
		|	Table.Series                                     AS Series,
		|	Table.BillOfMaterials                              AS BillOfMaterials,
		|	Table.Purpose                                AS Purpose,
		|	Table.Department                             AS Department,
		|	SUM(Table.Count)                         AS CountByDocument,
		|	SUM(Table.Count)                         AS ToOrder,
		|	0                                                 AS Count,
		|	0                                                 AS NumberOfPackages
		|FROM
		|	Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS Table
		|WHERE
		|	Table.Ref = &Ref
		|	AND Table.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|	AND NOT Table.Canceled
		|	AND NOT Table.Products = VALUE(Catalog.Products.EmptyRef)
		|
		|GROUP BY
		|	Table.UnderRepairProduct,
		|	Table.UnderRepairVariant,
		|	Table.UnderRepairBatch,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Series,
		|	Table.Package,
		|	Table.BillOfMaterials,
		|	Table.Department,
		|	Table.Purpose
		|
		|ORDER BY
		|	UnderRepairProduct,
		|	UnderRepairVariant,
		|	UnderRepairBatch,
		|	LineNumber
		|";
		
		ParentRow = Undefined;
		
		GoodsTable = Query.Execute().Unload();
		For Each String In GoodsTable Do
			
			If ParentRow = Undefined
				Or ParentRow.UnderRepairProduct <> String.UnderRepairProduct
				Or ParentRow.UnderRepairVariant <> String.UnderRepairVariant
				Or ParentRow.UnderRepairBatch <> String.UnderRepairBatch Then
				ParentRow = Goods.GetItems().Add();
				ParentRow.UnderRepairProduct   = String.UnderRepairProduct;
				ParentRow.UnderRepairVariant = String.UnderRepairVariant;
				ParentRow.UnderRepairBatch          = String.UnderRepairBatch;
				ParentRow.Description = ProductsClientServer.ProductPresentation(
					ParentRow.UnderRepairProduct,
					ParentRow.UnderRepairVariant,,
					ParentRow.UnderRepairBatch);
				ParentRow.Level = 0;
			EndIf;
			
			NewRow = ParentRow.GetItems().Add();
			FillPropertyValues(NewRow, String);
			NewRow.Description = ProductsClientServer.ProductPresentation(
				NewRow.Products, NewRow.Characteristic,, NewRow.Series);
			NewRow.Level = 1;
			NewRow.Mark = True;
			
		EndDo;
		
		Template = GoodsTable.CopyColumns("Products,Characteristic,Series,BillOfMaterials,Department,Purpose,Count,NumberOfPackages");
		TemplateAddress = PutToTempStorage(Template, UUID)
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	If Goods.GetItems().Count() > 1 Then
		Items.FormCreateDocument.Title = NStr("vi = 'Tạo chứng từ';
												|ru = 'Создать документы';
												|en = 'Create documents'; fa = 'ایجاد اسناد';
												|it = 'Creare documenti';
												|pl = 'Utwórz dokumenty';
												|tr = 'Belge oluştur'");
	EndIf;
	
EndProcedure

&AtServer
Function ResultIsAtServer()
	
	Result = New Structure;
	Result.Insert("Basis", Parameters.DocumentReference);
	Result.Insert("FillingData", New Array);
	
	Template = GetFromTempStorage(TemplateAddress); // ValueTable
	
	For Each ProductLine In Goods.GetItems() Do
		GoodsTable = Template.CopyColumns(); 
		For Each RowWork In ProductLine.GetItems() Do
			If RowWork.Mark Then
				NewRow = GoodsTable.Add();
				FillPropertyValues(NewRow, RowWork);
				NewRow.Count = RowWork.ToOrder;
				NewRow.NumberOfPackages = RowWork.ToOrder;
			EndIf;
		EndDo;
		If GoodsTable.Count() > 0 Then
			FillingData = FillingDataConstructor();
			FillingData.HeaderAttributes.UnderRepairProduct   = ProductLine.UnderRepairProduct;
			FillingData.HeaderAttributes.UnderRepairVariant = ProductLine.UnderRepairVariant;
			FillingData.HeaderAttributes.UnderRepairBatch          = ProductLine.UnderRepairBatch;
			FillingData.AddressGoods = PutToTempStorage(GoodsTable, New UUID());
			Result.FillingData.Add(FillingData);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Procedure SelectOrClearAll(Form, Value)
	
	For Each ProductLine In Form.Goods.GetItems() Do
		For Each RowWork In ProductLine.GetItems() Do
			RowWork.Mark = Value;
		EndDo;
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function FillingDataConstructor()
	
	HeaderAttributes = New Structure;
	HeaderAttributes.Insert("ProductionProcessType", PredefinedValue("Enum.ProductionProcessTypes.PerformRM"));
	HeaderAttributes.Insert("UnderRepairProduct");
	HeaderAttributes.Insert("UnderRepairVariant");
	HeaderAttributes.Insert("UnderRepairBatch");
	
	Return New Structure("HeaderAttributes, AddressGoods", HeaderAttributes);
	
EndFunction

#EndRegion