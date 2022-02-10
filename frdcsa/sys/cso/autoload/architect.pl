related(X,Y) :-
	relatedSystems(List),
	member(X,List),
	member(Y,List),
	X \== Y.

system(X) :-
	related(X,_).
system(Y) :-
	related(_,Y).

listSystems :-
	setof(X,system(X),List),view(List).


% % % INCORRECT VERSION
% % computeTransitiveClosure(BinaryPredicate,Start) :-
% % 	setof(X,X^transitiveClosure(BinaryPredicate,Start,X),List),
% % 	view(List).

% % transitiveClosure(BinaryPredicate,X,X).
% % transitiveClosure(BinaryPredicate,X,Z) :-
% % 	call(BinaryPredicate,X,Y),
% % 	transitiveClosure(BinaryPredicate,Y,Z).


% % % LIKELY CORRECT VERSION
% % from http://stackoverflow.com/questions/26946133/definition-of-reflexive-transitive-closure
% :- meta_predicate closure0(2,?,?).
% :- meta_predicate closure(2,?,?).

% :- meta_predicate closure0(2,?,?,+). % internal

% closure0(R_2, X0,X) :-
% 	closure0(R_2, X0,X, [X0]).

% closure(R_2, X0,X) :-
% 	call(R_2, X0,X1),
% 	closure0(R_2, X1,X, [X1,X0]).

% closure0(_R_2, X,X, _).
% closure0(R_2, X0,X, Xs) :-
% 	call(R_2, X0,X1),
% 	non_member(X1, Xs),
% 	closure0(R_2, X1,X, [X1|Xs]).

% non_member(_E, []).
% non_member(E, [X|Xs]) :-
% 	dif(E,X),
% 	   non_member(E, Xs).