#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If (Parameters.Property("ExpenseItem")) Then
		ItemOfExpenditureFilter = Parameters.ExpenseItem;
		CommonClientServer.SetDynamicListFilterItem(List, "ExpenseItem", ItemOfExpenditureFilter);
		Title = String(ItemOfExpenditureFilter);
		ArticleDetails_1 = Common.ObjectAttributesValues(ItemOfExpenditureFilter,
			"CostAllocationOptionManag,CostAllocationOptionLocal,CostAllocationOptionTax");
		Items.SettingsManAccounting.Title =	String(ArticleDetails_1.CostAllocationOptionManag);
		Items.SettingsLocal.Title =	String(ArticleDetails_1.CostAllocationOptionLocal);
		Items.SettingsTaxAccounting.Title =	String(ArticleDetails_1.CostAllocationOptionTax);
	EndIf;
	
	ThisIsFormOfArticleCustomization = ValueIsFilled(ItemOfExpenditureFilter);
	
	// Visibility of columns
	Items.ExpenseItem.Visible = Not ThisIsFormOfArticleCustomization;
	Items.ExpenseItemCostAllocationOptionManag.Visible =	Not ThisIsFormOfArticleCustomization;
	Items.ExpenseItemCostAllocationOptionLocal.Visible =	Not ThisIsFormOfArticleCustomization;
	Items.ExpenseItemCostAllocationOptionTax.Visible =	Not ThisIsFormOfArticleCustomization;
	Items.SettingsManAccounting.ShowInHeader =	ThisIsFormOfArticleCustomization;
	Items.SettingsLocal.ShowInHeader =	ThisIsFormOfArticleCustomization;
	Items.SettingsTaxAccounting.ShowInHeader =	ThisIsFormOfArticleCustomization;
	
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(ThisObject);
	SetFormItemsVisibility()
	
EndProcedure


&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	
EndProcedure
#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListAfterDeleteRow(Item)
	
	Notify("ChangedSettingsForDistributionOfItemByItemExpenses");
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetFormItemsVisibility()
	
	
EndProcedure 

#EndRegion