
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Title = NStr("vi = 'Liên kết mục báo cáo';
				|ru = 'Ссылка на элемент отчета';
				|en = 'Reference to the report item'; fa = 'Reference to the report item';
				|it = 'Link per l''elemento del report';
				|pl = 'Odnośnik do elementu raportu';
				|tr = 'Rapor öğesine bağlantı'");
	
	ObjectData = Catalogs.FinancialReportItems.FormWhenCreatedOnServer(ThisObject);
	Attributes = Common.ObjectAttributesValues(Object.LinkedItem1, "Owner, NameForPrinting");
	AssociatedAccountingKind = Attributes.Owner;
	NameOfTheAssociatedElement = Attributes.NameForPrinting;
	Description = ObjectData.NameForPrinting;
	If IsBlankString(NameOfTheAssociatedElement) And Not IsBlankString(Description) Then
		NameOfTheAssociatedElement = ObjectData.NameForPrinting;
	EndIf;
	ItemsKinds = Enums.FinancialReportItemKinds;
	ThisIsIndicator = ObjectData.ItemKind = ItemsKinds.MonetaryIndicator
					Or ObjectData.ItemKind = ItemsKinds.NonMonetaryItem
					Or ObjectData.ItemKind = ItemsKinds.DerivedItem
					Or (ObjectData.ItemKind = ItemsKinds.TotalByGroup And ObjectData.ThisIsReference);

	Items.ReverseSign.Visible = ThisIsIndicator;
	Items.SelectItem.Visible = ThisIsIndicator;
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	AdditionalMode_ = Enums.AdditionalModesOfReportItems.LinkedItem1;
	Catalogs.FinancialReportItems.FormBeforeWritingToServer(ThisObject, CurrentObject, Cancel, AdditionalMode_);

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)

	If ValueIsFilled(ItemAddressInStorage) Then
		StandardProcessing = False;
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure NameForPrintingOnChange(Item)

	Object.Description = Object.NameForPrinting;

EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)

	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");

EndProcedure

&AtClient
Procedure LinkedItem1Click(Item, StandardProcessing)

	StandardProcessing = False;
	FormParameters = New Structure;
	FormParameters.Insert("Key", AssociatedAccountingKind);
	FormParameters.Insert("CurrentReportItem", Object.LinkedItem1);
	OpenForm("Catalog.FinancialReportTypes.ObjectForm",FormParameters);
	Close();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)

	FinancialReportingClient.FinishEditingReportElement(ThisObject);

EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion
