
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Zakolovok = NStr("vi = 'Đặc tính mặt hàng: %1';
					|ru = 'Характеристики номенклатуры: %1';
					|en = 'Item variant: %1'; fa = 'Item variant: %1';
					|it = 'Caratteristiche degli articoli: %1';
					|pl = 'Charakterystyka nomenklatury: %1';
					|tr = 'Ürün varyantları: %1'");
	Title = StrReplace(Zakolovok, "%1", Parameters.Products);

	ExceptionCharacteristics = Parameters.ListOfExceptionCharacteristics.UnloadValues();
	
	Query = New Query();
	Query.Text =
	"SELECT ALLOWED
	|	ItemsCharacteristics.Ref AS Characteristic,
	|	CASE
	|		WHEN NOT &ThereAreExceptions
	|				OR ItemsCharacteristics.Ref IN (&ExceptionCharacteristics)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Selected_5
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		ON (CASE
	|				WHEN Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|					THEN Products.Ref
	|				WHEN Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|					THEN Products.ItemVariantsOwner
	|				WHEN Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|					THEN Products.ProductKind
	|				ELSE UNDEFINED
	|			END = ItemsCharacteristics.Owner)
	|WHERE
	|	Products.Ref = &Products
	|	AND Products.UseVariants <> VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|	AND NOT ItemsCharacteristics.DeletionMark";
	
	Query.SetParameter("Products",                   Parameters.Products);
	Query.SetParameter("ExceptionCharacteristics",       ExceptionCharacteristics);
	Query.SetParameter("ThereAreExceptions",                 ExceptionCharacteristics.Count()>0);
	CharacteristicTable.Load(Query.Execute().Unload());
	
EndProcedure

#EndRegion

#Region EventHandlersForCharacteristicTableElements

&AtClient
Procedure CharacteristicTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentRow = Items.CharacteristicTable.CurrentData;
	
	If Field = Items.CharacteristicTableCharacteristic Then
		
		If ValueIsFilled(CurrentRow.Characteristic) Then
			ShowValue(Undefined, CurrentRow.Characteristic);
		EndIf;
		
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectSelectedRows(Command)
	RowsArray = Items.CharacteristicTable.SelectedRows;
	SelectSelectedRowsOnServer(RowsArray);
EndProcedure

&AtClient
Procedure ClearSelectedRows(Command)
	RowsArray = Items.CharacteristicTable.SelectedRows;
	SelectSelectedRowsOnServer(RowsArray, False);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SelectSelectedRowsOnServer(RowsArray, SelectionValue = True)
	
	For Each RowID In RowsArray Do
		TableRow = CharacteristicTable.FindByID(RowID);
		If TableRow.Selected_5 = (Not SelectionValue) Then
			TableRow.Selected_5 = SelectionValue;
		EndIf;
	EndDo;

EndProcedure

&AtClient
Procedure Save(Command)
	
	ClearMessages();
	If CharacteristicTable.FindRows(New Structure("Selected_5", True)).Count()= 0 Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Hãy chọn ít nhất một đặc tính.';
				|ru = 'Выберите хотя бы одну характеристику.';
				|en = 'Select at least one variant.'; fa = 'Select at least one variant.';
				|it = 'Seleziona almeno una caratteristica.';
				|pl = 'Wybierz co najmniej jedną charakterystykę.';
				|tr = 'En az bir özellik seç.'"),
			,
			"CharacteristicTable");
		Return
	EndIf;
	Close();
	NotifyChoice(StructureOfReturnedCharacteristics());
EndProcedure

&AtServer
Function StructureOfReturnedCharacteristics()
	ExceptionsList = New ValueList();
	ExceptionsList.LoadValues(CharacteristicTable.Unload(New Structure("Selected_5", True), "Characteristic").UnloadColumn("Characteristic"));
	
	AllCharacteristicsSelected = ExceptionsList.Count() = CharacteristicTable.Count();
	
	StructureOfReturnedCharacteristics = New Structure; 
	StructureOfReturnedCharacteristics.Insert("ExceptionCharacteristics", ExceptionsList);
	StructureOfReturnedCharacteristics.Insert("NumberOfExceptions", ?(AllCharacteristicsSelected,0,ExceptionsList.Count()));
	StructureOfReturnedCharacteristics.Insert("EntryType", ?(AllCharacteristicsSelected, 1, 2));
	
	Return StructureOfReturnedCharacteristics
EndFunction

#EndRegion
