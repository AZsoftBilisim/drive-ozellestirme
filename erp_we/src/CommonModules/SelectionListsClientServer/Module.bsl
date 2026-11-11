
#Region Private

Procedure Load(SettingName, ChoiceList)Export
	
	SearchHistory = CommonServerCall.CommonSettingsStorageLoad(SettingName, "");
	If SearchHistory <> Undefined Then
		ChoiceList.LoadValues(SearchHistory);
	EndIf;
	
EndProcedure

Procedure Save(SettingName, ChoiceList) Export
	
	CommonServerCall.CommonSettingsStorageSave(SettingName, "",ChoiceList.UnloadValues());
	
EndProcedure // Save()

Procedure UpdateSelectionList(ChoiceList, SearchString, SizeOfSelectionList = 1000) Export
	
	// Delete the item from the search history if it was there
	NumberOfFoundListItem = ChoiceList.FindByValue(SearchString);
	While NumberOfFoundListItem <> Undefined Do
		ChoiceList.Delete(NumberOfFoundListItem);
		NumberOfFoundListItem = ChoiceList.FindByValue(SearchString);
	EndDo;
	
	
	// And put it in the first place
	ChoiceList.Insert(0, SearchString);
	While ChoiceList.Count() > SizeOfSelectionList Do
		ChoiceList.Delete(ChoiceList.Count() - 1);
	EndDo;
	
EndProcedure // Refresh the Selection list()

Procedure AutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing) Export
	
	StandardProcessing = False;
	ChoiceData = New ValueList;
	
	FoundItemsCount = 0;
	For Each ListItem In Item.ChoiceList Do
		If Left(Upper(ListItem.Value),StrLen(TrimAll(Text))) = Upper(TrimAll(Text)) Then
			ChoiceData.Add(ListItem.Value);
			FoundItemsCount = FoundItemsCount + 1;
			If FoundItemsCount > 7 Then
				Break;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure // AutoPodbor()

#EndRegion
