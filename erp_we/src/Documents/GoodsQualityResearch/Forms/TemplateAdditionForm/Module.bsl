
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Products 	= Parameters.Products;
	Pattern 		= Parameters.Pattern;
	ItemVariantsAreUsed = Parameters.ItemVariantsAreUsed;
	If ItemVariantsAreUsed And ValueIsFilled(Parameters.Characteristic) Then
		Items.Characteristic.ChoiceList.Clear();
		Items.Characteristic.ChoiceList.Add(Parameters.Characteristic, String(Parameters.Characteristic));
		Characteristic = Items.Characteristic.ChoiceList[0].Value;
	EndIf;
	CharacteristicSelectionList.LoadValues(Parameters.CharacteristicSelectionList);
	Items.Products.ChoiceList.LoadValues(Parameters.ProductSelectionList);
	SetConditionalAppearance();

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CharacteristicStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	Item.ChoiceList.Clear();
	ListOfCharacteristics = FindCharacteristicsInArrayOfStructures(CharacteristicSelectionList.UnloadValues(), Products, "Products");
	For Each ArrayElement In ListOfCharacteristics Do
		Item.ChoiceList.Add(ArrayElement, String(ArrayElement));
	EndDo;
	If Not ValueIsFilled(Characteristic) And ListOfCharacteristics.Count() > 0 Then
		Characteristic = Items.Characteristic.ChoiceList[0].Value;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsOnChange(Item)
	
	UseCharacteristics();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OkCommand(Command)
	
	CompleteEditing();
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	Modified = False;
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CompleteEditing()
		
	Close(New Structure("Pattern,Products,Characteristic",Pattern, Products, Characteristic));
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	Items.Characteristic.Visible = UseItemVariants;
	
	ConfigureDependentElements();

EndProcedure

&AtServer
Procedure ConfigureDependentElements()
	
	If ItemVariantsAreUsed Then
		Items.Characteristic.Enabled = True;
		Items.Characteristic.InputHint = "";
	Else
		Items.Characteristic.Enabled = False;
		Items.Characteristic.InputHint = NStr("vi = '<không sử dụng đặc tính>';
												|ru = '<характеристики не используются>';
												|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
												|it = '<le caratteristiche non vengono usate>';
												|pl = '<charakterystyki nie dotyczą>';
												|tr = '<varyantlar kullanılmamaktadır>'");
	EndIf;

EndProcedure

&AtServer
Function FindCharacteristicsInArrayOfStructures(Array, SoughtValue, Var_Key)
	
	Result = New Array;
	For Each ArrayElement In Array Do
		If ArrayElement[Var_Key] = SoughtValue Then
			Result.Add(ArrayElement["Characteristic"]);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Procedure UseCharacteristics()
	
	ItemVariantsAreUsed = Catalogs.Products.ItemVariantsAreUsed(Products);
	ConfigureDependentElements();
	
EndProcedure

#EndRegion
