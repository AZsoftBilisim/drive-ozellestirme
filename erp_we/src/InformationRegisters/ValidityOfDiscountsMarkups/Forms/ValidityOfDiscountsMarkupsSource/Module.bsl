
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ActionSource = Parameters.Source;
	
	DiscountsMarkupsServer.WhenCreatingDiscountSourcesOnServer(ThisObject, ActionSource, False);
	
	Items.SetStatusValid.Visible = AccessRight("Update", Metadata.InformationRegisters.ValidityOfDiscountsMarkups);
	Items.SetTheStatusNotValid.Visible = AccessRight("Update", Metadata.InformationRegisters.ValidityOfDiscountsMarkups);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

// Parameters:
// 	EventName - String - Event name
// 	Parameter - Structure - with properties:
// 		* Source - Array of CatalogRef.DiscountsMarkups - 
// 		* DiscountMarkup - Array of CatalogRef.DiscountMarkupTerms -
// 	Source - ClientApplicationForm - Event source
&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ValidityOfDiscountsMarkups" And Parameter.Source.Find(ActionSource) <> Undefined Then
		UpdateDiscountTree();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OptionForDisplayingDiscountsOnChange(Item)
	
	UpdateDiscountTree();
	
EndProcedure

&AtClient
Procedure InformationOnDiscountValidityURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	If Var_URL = "ConfigureDiscounts" Then
			
			OpenForm("Catalog.DiscountsMarkups.ListForm", ,ThisObject);
			
	EndIf;
	
EndProcedure

&AtClient
Procedure SliceDateOnChange(Item)
	
	UpdateDiscountTree();
	
EndProcedure

#EndRegion

#Region EventHandlersForTablePartDiscountsMargins

&AtClient
Procedure DiscountsMarkupsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If ValueIsFilled(Items.DiscountsMarkups.CurrentData.Ref) Then
		ShowValue(Undefined, Items.DiscountsMarkups.CurrentData.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure DiscountsMarkupsOnActivateRow(Item)
	
	AttachIdleHandler("Attachable_ListOnActivateRow", 0.1, True);
	
EndProcedure

&AtClient
Procedure DiscountsMarkupsBeforeExpand(Item, String, Cancel)
	
	DiscountsMarkupsClient.SaveWhetherTreeNodeIsExpandedInList(String, Items.DiscountsMarkups, ExpandedTreeNodes, True);
	
EndProcedure

&AtClient
Procedure DiscountsMarkupsBeforeCollapse(Item, String, Cancel)
	
	DiscountsMarkupsClient.SaveWhetherTreeNodeIsExpandedInList(String, Items.DiscountsMarkups, ExpandedTreeNodes, False);
	
EndProcedure

#EndRegion 

#Region FormCommandsEventHandlers

&AtClient
Procedure DiscountMarkupValidityHistory(Command)
	
	DiscountsMarkupsClient.OpenStatusChangeHistoryForm(ThisObject, ActionSource);
	
EndProcedure

&AtClient
Procedure SetStatusValid(Command)
	
	DiscountsMarkupsClient.OpenStatusSettingForm(
		ThisObject,
		PredefinedValue("Enum.DiscountValidityStatuses.Valid"), 
		ActionSource);
	
EndProcedure

&AtClient
Procedure SetTheStatusNotValid(Command)
	
	DiscountsMarkupsClient.OpenStatusSettingForm(
		ThisObject,
		PredefinedValue("Enum.DiscountValidityStatuses.NotValid"),
		ActionSource);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
		
	DiscountsMarkupsServer.SetConditionalAppearanceOfDiscountSourceForm(ConditionalAppearance, Items);

EndProcedure

&AtServer
Procedure BuildDiscountMarkUpTree()
	
	DiscountsMarkupsServer.BuildDiscountMarkUpTreeInForm(ThisObject, ActionSource);
	UpdateUsageOfDiscountsMarkups(ActivatedDiscountMarkup);
	
EndProcedure

&AtClient
Procedure Attachable_ListOnActivateRow()
	
	CurrentData = Items.DiscountsMarkups.CurrentData;
	DiscountMarkup = ?(CurrentData = Undefined Or CurrentData.IsFolder, Undefined, CurrentData.Ref);
	
	If DiscountMarkup <> ActivatedDiscountMarkup Then
		UpdateUsageOfDiscountsMarkups(DiscountMarkup);
		ActivatedDiscountMarkup = ?(CurrentData = Undefined, Undefined, CurrentData.Ref);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateUsageOfDiscountsMarkups(DiscountMarkup)
	
	UsingMarkUpDiscount = DiscountsMarkupsServer.UsingMarkUpDiscount(DiscountMarkup, SliceDate);
	DiscountsMarkupsServer.CreateInformationLabelUsingDiscountsMargins(InformationOnDiscountValidity,
	                                                                                UsingMarkUpDiscount,
	                                                                                "ConfigureDiscounts");
	
EndProcedure

&AtClient
Procedure UpdateDiscountTree()
	
	BuildDiscountMarkUpTree();
	DiscountsMarkupsClient.ExpandDiscountTreeRecursively(DiscountsMarkups, Items.DiscountsMarkups, ExpandedTreeNodes);
	DiscountsMarkupsClient.PositionOnValueInTree(ActivatedDiscountMarkup, DiscountsMarkups, Items.DiscountsMarkups, "Ref");
	
EndProcedure


#EndRegion

