///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateTableRowsCounters();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAdditionalProperties

&AtClient
Procedure ObjectPropertiesOnChange(Item)
	
	UpdateTableRowsCounters();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdateTableRowsCounters()
	
	SetPageTitle(Items.AdditionalPropertiesPage, Object.ObjectProperties, NStr("vi = 'Thuộc tính bổ sung';
																				|ru = 'Дополнительные свойства';
																				|en = 'Additional properties'; fa = 'خاصیت‌های تکمیلی';
																				|it = 'Proprietà aggiuntive';
																				|pl = 'Dodatkowe właściwości';
																				|tr = 'Ek özellikler'"));
	
EndProcedure

&AtClient
Procedure SetPageTitle(PageItem, AttributeTabularSection, DefaultTitle)
	
	PageHeader = DefaultTitle;
	If AttributeTabularSection.Count() > 0 Then
		PageHeader = DefaultTitle + " (" + AttributeTabularSection.Count() + ")";
	EndIf;
	PageItem.Title = PageHeader;
	
EndProcedure

#EndRegion