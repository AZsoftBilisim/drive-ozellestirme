///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ProcessPassedParameters();
	
	SetPredefinedFilters();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OwnerOnChange(Item)
	
	OnChangeOwnerAtServer();
	
EndProcedure

&AtClient
Procedure OwnerClearing(Item, StandardProcessing)
	
	OnChangeOwnerAtServer();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ProcessPassedParameters()
	
	If Parameters.Filter.Property("Owner")
		And ValueIsFilled(Parameters.Filter.Owner) Then
		
		Owner = Parameters.Filter.Owner;
		Items.Owner.Visible = False;
		
	EndIf;
	
	If Not ValueIsFilled(Owner) Then
		Owner = EmailOperations.SystemAccount();
		OnChangeOwnerAtServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetPredefinedFilters()
	
	CommonClientServer.SetDynamicListFilterItem(List,
	                                                                        "DeletionMark",
	                                                                        False,
	                                                                        DataCompositionComparisonType.Equal,
	                                                                        NStr("vi = 'Chỉ hiển thị các thư mục chưa đặt dấu xóa';
																				|ru = 'Отображение только не помеченных на удаление папок';
																				|en = 'Show only folders not marked for deletion'; fa = 'Show only folders not marked for deletion';
																				|it = 'Visualizzazione solo di cartelle non contrassegnate per l''eliminazione';
																				|pl = 'Wyświetlenie tylko nie zaznaczonych do usunięcia folderów';
																				|tr = 'Sadece silinmek için işaretlenmeyen klasörleri göster'"),
	                                                                        True, 
	                                                                        DataCompositionSettingsItemViewMode.Inaccessible);
	
EndProcedure

&AtServer
Procedure OnChangeOwnerAtServer()
	
	CommonClientServer.SetDynamicListFilterItem(List,
	                                                                        "Owner",
	                                                                        Owner,
	                                                                        DataCompositionComparisonType.Equal,
	                                                                        NStr("vi = 'Lọc theo chủ sở hữu thư mục';
																				|ru = 'Отбор по владельцу папок';
																				|en = 'Filter by folder owner'; fa = 'Filter by folder owner';
																				|it = 'Filtro per proprietario delle cartelle';
																				|pl = 'Filtr według właściciela folderów';
																				|tr = 'Klasör sahiplerine göre filtrele'"),
	                                                                        ValueIsFilled(Owner), 
	                                                                        DataCompositionSettingsItemViewMode.Inaccessible);
	
EndProcedure

#EndRegion