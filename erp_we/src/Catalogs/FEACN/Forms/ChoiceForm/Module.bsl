#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Items.FormSelectFromFEACN.Visible = AccessRight("Edit", Metadata.Catalogs.FEACN);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "UpdateAfterAddingFuelInjectionPump" 
		Or EventName = "EndOfLoadingFuelTaxData" Then
		Items.List.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
	AdditionalParameters = New Structure;
	If Copy Then
		FillingValues = New Structure;
		FillingValues.Insert("Code", Item.CurrentData.Code);
		FillingValues.Insert("Description", Item.CurrentData.Description);
		AdditionalParameters.Insert("FillingValues", FillingValues);
	EndIf;
	
	Notification = New CallbackDescription("DoQueryBoxCompletion", ThisObject, AdditionalParameters);
	
	QueryText = NStr("vi = 'Có thể chọn mặt hàng theo mã XNK từ bảng mã hiệu.
		|Chọn?';
		|ru = 'Есть возможность подобрать товарную номенклатуру ВЭД из классификатора.
		|Подобрать?';
		|en = 'There is a possibility to pick a Foreign Economic Activity Commodity Nomenclature classification from the classifier.
		|Pick?'; fa = 'There is a possibility to pick a Foreign Economic Activity Commodity Nomenclature classification from the classifier.
		|Pick?';
		|it = 'C''è un''opportunità di selezionare la nomenclatura merceologica dell''attività economica estera dal classificatore.
		|Selezionare?';
		|pl = 'Istnieje możliwość wyboru nomenklatury towarowej zagranicznej działalności gospodarczej z klasyfikatora.
		|Wybrać?';
		|tr = 'Sınıflandırıcıdan Dış Ekonomik Faaliyetin ürün öğesini seçmek mümkündür.
		|Seç?'");
	
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.No);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectFromFEACN(Command)

	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure DoQueryBoxCompletion(Result, AdditionalParameters) Export

	If Result = DialogReturnCode.Yes Then
		SelectFromFEACN(Undefined);
	Else
		OpenForm("Catalog.FEACN.Form.ItemForm", AdditionalParameters, ThisObject);
	EndIf;

EndProcedure

&AtClient
Procedure PickFromClassifierCompletion(SelectionResult, AddlParameters) Export
	
	If SelectionResult = Undefined Then
		Return;
	EndIf;
	
	NewItem = AddClassifierElement(SelectionResult);
	
	NotifyChanged(NewItem);
	
	Items.List.CurrentRow = NewItem;
	
EndProcedure 

&AtServerNoContext
Function AddClassifierElement(ItemProperties)
	
	If Not ValueIsFilled(ItemProperties.Code) Then
		Return Catalogs.FEACN.EmptyRef();
	EndIf;
	
	ElementOfFuelTaxCode = Catalogs.FEACN.CreateUpdateClassifierElement(ItemProperties);
	
	Return ElementOfFuelTaxCode;
	
EndFunction

#EndRegion