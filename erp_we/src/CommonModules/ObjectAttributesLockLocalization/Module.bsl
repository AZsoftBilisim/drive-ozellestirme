
#Region Public

// Define metadata objects whose Manager modules restrict the ability
// to edit details using the export function getblockablerequisits of the Object.
//
// The getblockablerequisits function of an Object must return an Array-string value in the format
// Requisitname[;Formelementname,...], where Requisitname is the name of the object's props, Formelementname is
// the name of the form element associated with the props. For Example, " Object.Author", "Field Author".
//
// The label field associated with the item is not blocked. If you want to block,
// enter the name of the label element after the semicolon, as described above.
//
// Parameters:
//   Objects - Map - for the key, specify the full name of the metadata object
//             connected to the "Prohibit editing object details" subsystem
//             .for the value, specify an empty string.
//
// Example:
//   Objects.Insert(Metadata.Documents.The buyer's order.Fullname(), "");
//
//   At the same time, the code is placed in the module of the requester document manager:
//   // See ObjectAttributesLockOverridable.OnDefineObjectsWithLockedAttributes.
//   
//   	Function Getblockable Object Session() Export
//   	Blockedrev sessions = New Array;
//   	Sessions are being blocked.Add("Organization"); // block editing of the Organization Attribute
//   Refunds are blockedrev sessions;
//   The end of the function
//
Procedure OnDefineObjectsWithLockedAttributes(Objects) Export
	
	
EndProcedure

#EndRegion