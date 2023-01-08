## Projetcompilation

# Ce qui a ete fait:

j'ai implemente arithmetique variable fonctions structures et rescursion
a tout les niveaux

# Probleme:
    On a App qui a un pb au niveau de sa priorite par exemple 4 * fact (n - 1) m
    On a (4 * fact (n-1)) m
    Mais cela marche correctement si on met 4 * fact (n - 1) (m)
# Extension:
    Argument () pour le let
    j'ai rajoute les listes pour obtenir ou modifier certains element:
        j ai mis une GetList -> l.[nb] pour obtenir le enieme element
        j ai mis une SetList -> l.[nb] <- e pour modifier le enieme element
        donc j ai implementer les liste a moitie array
        j'ai aussi rajoute x::l pour les list
        [] est d'un type random vu qu'on sait pas son type
    print pour voir les listes et les struct et les enum et type algebrique
    j'ai rajoute les type enum et algebrique mais je n'ai pas eu le temps d'implementer match
    j'ai aussi rajoute l'egalite structurelle

# Difficulte:
    On a les priorite pour certains token comme les fleche ou IDENT 
