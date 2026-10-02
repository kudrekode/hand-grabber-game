export type Visual = 'cherry'|'strawberry'|'apple'|'orange'|'coconut'|'watermelon'|'football'|'cone'|'bin'|'trolley'|'car'|'bus';
export interface ObjectDefinition { id: string; name: string; size: number; scoreValue: number; coinValue: number; visual: Visual; category: 'fruit'|'street'; color: string }
export const OBJECTS: ObjectDefinition[] = [
  ['cherry','Cherry',5,5,1,'fruit','#ec4564'], ['strawberry','Strawberry',8,8,1,'fruit','#f75262'],
  ['apple','Apple',12,12,2,'fruit','#f16c47'], ['orange','Orange',15,15,2,'fruit','#ffb540'],
  ['coconut','Coconut',22,20,3,'fruit','#a7744c'], ['watermelon','Watermelon',35,30,4,'fruit','#6bd68c'],
  ['football','Football',45,40,5,'street','#e9eeee'], ['cone','Traffic Cone',55,50,6,'street','#ff924b'],
  ['bin','Bin',70,70,8,'street','#87b8a6'], ['trolley','Shopping Trolley',90,90,10,'street','#a3cad0'],
  ['car','Car',180,150,20,'street','#ad9df8'], ['bus','Bus',360,250,30,'street','#ffce59'],
].map(([id,name,size,scoreValue,coinValue,category,color]) => ({id,name,size,scoreValue,coinValue,category,color,visual:id} as ObjectDefinition));
